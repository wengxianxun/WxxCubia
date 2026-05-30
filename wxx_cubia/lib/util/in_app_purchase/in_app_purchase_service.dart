import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

/**
 *
 *
 * // 初始化内购管理器
    await InAppPurchaseManager().init();

    // 检查内购是否可用
    if (!InAppPurchaseManager().isAvailable) {
    // 显示内购不可用的提示
    }

    // 购买锤子道具
    InAppPurchaseManager().purchaseProduct(
    'com.wxx.popstar.hammer_1',
    callback: (productId, success, errorMessage) {
    if (success) {
    // 显示购买成功提示
    } else {
    // 显示购买失败提示
    }
    },
    );

    // 恢复购买（主要用于iOS）
    InAppPurchaseManager().restorePurchases(
    callback: (success, errorMessage) {
    if (success) {
    // 显示恢复成功提示
    } else {
    // 显示恢复失败提示
    }
    },
    );
 *
 *
 */
class InAppPurchaseManager {
  static final InAppPurchaseManager _instance =
      InAppPurchaseManager._internal();
  factory InAppPurchaseManager() => _instance;
  InAppPurchaseManager._internal();

  List<ProductCommon> _products = [];
  final Map<String, ProductCommon> _originalProducts = {};
  bool _isAvailable = false;
  final Set<String> _processedTransactionIds = {}; // 追踪已处理的交易
  StreamSubscription<Purchase>? _purchaseUpdatedSubscription;
  StreamSubscription<PurchaseError>? _purchaseErrorSubscription;
  late final _connectionSub;
  // 购买回调函数
  Function(String productId, bool success, String? errorMessage)?
  _purchaseCallback;

  // 初始化内购
  Future<void> init() async {
    try {
      // 首先尝试结束可能存在的连接
      bool result = await FlutterInappPurchase.instance.endConnection();
      if (result) {
        debugPrint('成功');
      } else {
        debugPrint('失败');
      }
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('Note: endConnection failed (might not be connected): $e');
    }

    try {
      // 初始化连接
      bool result = await FlutterInappPurchase.instance.initConnection();
      if (result) {
        debugPrint('成功');
      } else {
        debugPrint('失败');
      }
      _connectionSub = FlutterInappPurchase.instance.connectionUpdated.listen((
        connected,
      ) {
        debugPrint('In-app purchase is available${connected}');
        if (connected == true) {
          _isAvailable = true;
        } else {
          _isAvailable = false;
        }
      });

      debugPrint('In-app purchase is available');

      // 设置监听器
      setupListeners();

      // 获取商品
      await getProducts();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  // 获取商品列表
  Future<void> getProducts() async {
    try {
      // 道具商品ID - 基于PopStar游戏的道具购买需求
      const List<String> productIds = [
        'com.wxx.popstar.itembox1', // 道具盒子
      ];

      final inAppProducts = await FlutterInappPurchase.instance.fetchProducts(
        skus: productIds,
        type: ProductQueryType.InApp,
      );

      _originalProducts.clear();
      for (final product in inAppProducts) {
        final productKey = product.id;
        _originalProducts[productKey] = product;

        debugPrint('Product: ${product.id} - ${product.title ?? 'No title'}');
        debugPrint('  Price: ${product.price ?? 'No price'}');
        debugPrint('  Currency: ${product.currency ?? 'No currency'}');
        debugPrint('  Description: ${product.description ?? 'No description'}');
      }

      _products = List<ProductCommon>.from(inAppProducts);

      // 获取已购买的商品
      // await _getPastPurchases();
    } catch (e) {
      debugPrint('Error getting products: $e');
    }
  }

  // 设置监听器
  void setupListeners() {
    _purchaseUpdatedSubscription = FlutterInappPurchase
        .instance
        .purchaseUpdatedListener
        .listen(
          (purchase) {
            debugPrint('🎉 Purchase update received!');
            debugPrint('ProductId: ${purchase.productId}');
            debugPrint('ID: ${purchase.id}');
            final txId = purchase.transactionIdFor;
            debugPrint('TransactionId: ${txId ?? 'N/A'}');
            debugPrint('PurchaseToken: ${purchase.purchaseToken}');
            _handlePurchase(purchase);
          },
          onError: (Object error) {
            debugPrint('❌ Purchase stream error: $error');
            _purchaseCallback?.call('', false, error.toString());
          },
          onDone: () {
            debugPrint('Purchase stream closed');
          },
        );

    // 错误监听
    _purchaseErrorSubscription = FlutterInappPurchase
        .instance
        .purchaseErrorListener
        .listen(
          (purchaseError) {
            debugPrint('❌ Purchase error received!');
            debugPrint('Error code: ${purchaseError.code}');
            debugPrint('Error message: ${purchaseError.message}');
            _handlePurchaseError(purchaseError);
          },
          onError: (Object error) {
            debugPrint('❌ Error stream error: $error');
          },
        );
  }

  void _handlePurchaseError(PurchaseError error) {
    debugPrint(
      '❌  Purchase Error Code: ${error.code} Message: ${error.message}',
    );
    _purchaseCallback?.call('', false, error.message);
  }

  // 获取过去的购买记录
  Future<void> _getPastPurchases() async {
    try {
      final purchases = await FlutterInappPurchase.instance
          .getAvailablePurchases();
      if (purchases != null) {
        for (final purchase in purchases) {
          _handlePurchase(purchase);
        }
      }
    } catch (e) {
      debugPrint('Error getting past purchases: $e');
    }
  }

  // 处理单个购买
  Future<void> _handlePurchase(Purchase purchase) async {
    debugPrint('🎯 Purchase update received: ${purchase.productId}');
    debugPrint('  Platform: ${purchase.platform}');
    debugPrint('  Purchase state: ${purchase.purchaseState}');
    final transactionId = purchase.transactionIdFor;
    final androidStateValue = purchase.androidPurchaseStateValue;
    final iosTransactionState = purchase.iosTransactionState;
    final acknowledgedAndroid = purchase.androidIsAcknowledged;
    debugPrint('  Transaction ID: ${transactionId ?? 'N/A'}');
    debugPrint('  Purchase token: ${purchase.purchaseToken}');

    // 检查是否已经处理过这个交易
    if (transactionId != null &&
        _processedTransactionIds.contains(transactionId)) {
      debugPrint('⚠️ Transaction already processed: $transactionId');
      return;
    }

    // 确定购买是否成功
    bool isPurchased = false;

    if (Platform.isAndroid && purchase is PurchaseAndroid) {
      // Android购买状态检查
      final bool condition1 = purchase.purchaseState == PurchaseState.Purchased;
      final bool condition2 =
          acknowledgedAndroid == false &&
          purchase.purchaseToken != null &&
          purchase.purchaseToken!.isNotEmpty &&
          purchase.purchaseState == PurchaseState.Purchased;
      final bool condition3 =
          androidStateValue == AndroidPurchaseState.Purchased.value;

      isPurchased = condition1 || condition2 || condition3;
    } else if (Platform.isIOS && purchase is PurchaseIOS) {
      // iOS购买状态检查
      final bool condition1 = iosTransactionState == TransactionState.purchased;
      bool condition2 =
          purchase.purchaseToken != null && purchase.purchaseToken!.isNotEmpty;
      final bool condition3 = transactionId != null;

      isPurchased = condition1 || condition2 || condition3;
    }

    if (!isPurchased) {
      debugPrint('❓ 未检测到购买成功');
      _purchaseCallback?.call(purchase.productId, false, '未检测到购买成功');
      return;
    }

    debugPrint('✅ 检测到购买成功: ${purchase.productId}');

    // 将此交易标记为已处理
    if (transactionId != null) {
      _processedTransactionIds.add(transactionId);
    }

    // 服务器端验证（实际应用中应该实现）
    bool isValid = await _verifyPurchaseOnServer(purchase);
    if (!isValid) {
      debugPrint('❌ 服务器验证失败');
      _purchaseCallback?.call(purchase.productId, false, '服务器验证失败');
      return;
    }

    // 验证成功后，完成交易
    try {
      await FlutterInappPurchase.instance.finishTransaction(
        purchase: purchase,
        isConsumable: true, // 道具为消耗品
      );
      debugPrint('交易已成功完成');

      // 发放道具给用户
      _deliverProduct(purchase.productId);

      // 通知购买成功
      _purchaseCallback?.call(purchase.productId, true, null);
    } catch (e) {
      debugPrint('完成交易时出错： $e');
      _purchaseCallback?.call(purchase.productId, false, '完成交易时出错');
    }
  }

  // 模拟服务器验证（实际应用中应替换为真实的服务器验证逻辑）
  Future<bool> _verifyPurchaseOnServer(Purchase purchase) async {
    // 在实际应用中，这里应该将购买凭证发送到服务器进行验证
    // 这里简单返回true模拟验证成功
    debugPrint('模拟服务器验证: ${purchase.productId}');
    return true;
  }

  // 发放商品
  void _deliverProduct(String productId) {
    debugPrint('发放商品: $productId');

    // 根据productId发放不同的道具
    switch (productId) {
      case 'com.wxx.popstar.hammer_1':
        _addHammer(1);
        break;
      case 'com.wxx.popstar.hammer_5':
        _addHammer(5);
        break;
      case 'com.wxx.popstar.refresh_1':
        _addRefresh(1);
        break;
      case 'com.wxx.popstar.refresh_5':
        _addRefresh(5);
        break;
      case 'com.wxx.popstar.color_changer_1':
        _addColorChanger(1);
        break;
      case 'com.wxx.popstar.color_changer_5':
        _addColorChanger(5);
        break;
      case 'com.wxx.popstar.special_offer':
        _addSpecialOffer();
        break;
    }
  }

  // 添加锤子道具
  void _addHammer(int count) {
    // 这里应该调用游戏中的道具管理类来添加锤子道具
    debugPrint('添加锤子道具 x$count');
    // 实际应用中应替换为：道具管理器.addHammer(count);
  }

  // 添加刷新道具
  void _addRefresh(int count) {
    // 这里应该调用游戏中的道具管理类来添加刷新道具
    debugPrint('添加刷新道具 x$count');
    // 实际应用中应替换为：道具管理器.addRefresh(count);
  }

  // 添加改色笔道具
  void _addColorChanger(int count) {
    // 这里应该调用游戏中的道具管理类来添加改色笔道具
    debugPrint('添加改色笔道具 x$count');
    // 实际应用中应替换为：道具管理器.addColorChanger(count);
  }

  // 添加特殊优惠包
  void _addSpecialOffer() {
    // 特殊优惠包可能包含多种道具
    debugPrint('添加特殊优惠包');
    _addHammer(3);
    _addRefresh(3);
    _addColorChanger(3);
  }

  // 购买商品
  Future<void> purchaseProduct(
    String productId, {
    Function(String productId, bool success, String? errorMessage)? callback,
  }) async {
    try {
      _purchaseCallback = callback;

      // 检查商品是否存在
      if (!_originalProducts.containsKey(productId)) {
        debugPrint('商品不存在: $productId');
        callback?.call(productId, false, '商品不存在');
        return;
      }

      final requestProps = RequestPurchaseProps.inApp((
        apple: RequestPurchaseIosProps(sku: productId, quantity: 1),
        google: RequestPurchaseAndroidProps(skus: [productId]),
        useAlternativeBilling: null,
      ));

      debugPrint('开始购买商品: $productId');
      await FlutterInappPurchase.instance.requestPurchase(requestProps);
    } catch (e) {
      debugPrint('Purchase error: $e');
      callback?.call(productId, false, '购买失败: $e');
    }
  }

  // 恢复购买（主要用于iOS）
  Future<void> restorePurchases({
    Function(bool success, String? errorMessage)? callback,
  }) async {
    try {
      debugPrint('开始恢复购买');
      final purchases = await FlutterInappPurchase.instance
          .getAvailablePurchases();

      if (purchases != null && purchases.isNotEmpty) {
        debugPrint('恢复了 ${purchases.length} 个购买');
        for (var purchase in purchases) {
          _handlePurchase(purchase);
        }
        callback?.call(true, null);
      } else {
        debugPrint('没有可恢复的购买');
        callback?.call(true, '没有可恢复的购买');
      }
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      callback?.call(false, '恢复购买失败: $e');
    }
  }

  // 获取商品信息
  ProductCommon? getProductById(String productId) {
    return _originalProducts[productId];
  }

  // 获取所有商品
  List<ProductCommon> get products => _products;

  // 检查内购是否可用
  bool get isAvailable => _isAvailable;

  // 清理资源
  Future<void> dispose() async {
    _purchaseUpdatedSubscription?.cancel();
    _purchaseErrorSubscription?.cancel();
    _purchaseCallback = null;
    _connectionSub?.cancel();
    try {
      await FlutterInappPurchase.instance.endConnection();
    } catch (e) {
      debugPrint('Error ending connection: $e');
    }
  }
}
