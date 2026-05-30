import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:wxx_cubia/pages/popstar_game/game/manager/game_data_manager.dart';
import 'package:wxx_cubia/util/ad/admob/ad_manager_rewarded.dart';
import 'package:wxx_cubia/util/huuua_button.dart';
import 'package:wxx_cubia/util/item_plus_widget.dart';

class AdCell extends StatefulWidget {
  final Function onRewardClaimed;
  final Function onAdClose;

  const AdCell({
    Key? key,
    required this.onRewardClaimed,
    required this.onAdClose,
  }) : super(key: key);

  @override
  _AdCellState createState() => _AdCellState();
}

class _AdCellState extends State<AdCell> {
  final AdManagerRewarded _adManager = AdManagerRewarded();
  bool isAdLoading = false;
  bool isAdLoaded = false;
  Timer? _cooldownTimer;
  bool _hasEarnedReward = false;
  int _retryCount = 0;
  static const int maxRetryCount = 3;

  final int hummberCount = 1;
  final int penCount = 1;
  final int refreshCount = 1;
  final int lifeCount = 1;

  @override
  void initState() {
    super.initState();
    _initializeAds();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    // 每秒钟更新一次冷却时间显示
    _cooldownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _initializeAds() async {
    // 设置广告加载中状态
    if (mounted) {
      setState(() {
        isAdLoading = true;
        isAdLoaded = false;
      });
    }
    // 加载刷新次数的激励广告
    await _adManager.loadRefreshTimesRewardedAd(
      onAdLoaded: (AdLoadResult result) {
        // 广告加载成功（可能是腾讯或Admob），重置重试计数器
        _retryCount = 0;
        if (mounted) {
          setState(() {
            isAdLoading = false;
            isAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: () {
        print('Failed to load refresh times rewarded ad');
        // 广告加载失败
        if (mounted) {
          setState(() {
            isAdLoading = false;
            isAdLoaded = false;
          });
        }
        // 检查重试次数
        _retryCount++;
        if (_retryCount < maxRetryCount) {
          print('广告加载失败，第$_retryCount次重试，最多重试$maxRetryCount次');
          // 失败后的重试逻辑
          Future.delayed(Duration(seconds: 3), () {
            if (mounted && !isAdLoading) {
              _initializeAds();
            }
          });
        } else {
          print('广告加载失败，已达到最大重试次数$maxRetryCount次，暂停重试');
        }
      },
    );
  }

  // 手动重试加载广告
  void _manualRetry() {
    _retryCount = 0; // 重置重试计数器
    _initializeAds();
  }

  // 将毫秒转换为分:秒格式
  String _formatCountdown(int milliseconds) {
    int seconds = milliseconds ~/ 1000;
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes}:${remainingSeconds < 10 ? '0$remainingSeconds' : remainingSeconds}";
  }

  Widget adBtn() {
    // 判断是否达到最大重试次数
    bool hasReachedMaxRetry = _retryCount >= maxRetryCount && !isAdLoaded;

    return HuuuaButton(
      icon: Icon(
        hasReachedMaxRetry
            ? Icons.refresh_rounded
            : Icons.video_collection_rounded,
        size: 20,
        color: Colors.white70,
      ),
      text: isAdLoading
          ? "loading".tr
          : hasReachedMaxRetry
          ? "retry".tr
          : !isAdLoaded
          ? "ad_load_failed".tr
          : GameDataManager().getRemainingAdsToday() <= 0
          ? "try_tomorrow".tr
          : (!GameDataManager().canWatchRewardedAd() &&
                GameDataManager().getTimeUntilNextAdAvailable() > 0)
          ? "${_formatCountdown(GameDataManager().getTimeUntilNextAdAvailable())}"
          : "Watch to Claim".tr,
      backgroundColor: isAdLoading
          ? Colors.grey
          : hasReachedMaxRetry
          ? Colors.blue
          : !isAdLoaded
          ? Colors.red.shade500
          : GameDataManager().getRemainingAdsToday() <= 0
          ? Colors.grey
          : (!GameDataManager().canWatchRewardedAd() &&
                GameDataManager().getTimeUntilNextAdAvailable() > 0)
          ? Colors.blueGrey
          : Colors.green,
      onTap: () {
        // 如果达到最大重试次数，执行手动重试
        if (hasReachedMaxRetry) {
          _manualRetry();
          return;
        }

        // 添加点击判断，只有在广告可以观看时才执行
        if (isAdLoading || !isAdLoaded) {
          return;
        }

        if (GameDataManager().getRemainingAdsToday() <= 0) {
          return;
        }

        if (!GameDataManager().canWatchRewardedAd() &&
            GameDataManager().getTimeUntilNextAdAvailable() > 0) {
          SmartDialog.showToast("ad_cooldown".tr, alignment: Alignment.center);
          return;
        }

        _adManager.showRewardedAd(
          onUserEarnedReward: (rewardItem) {
            debugPrint('Reward amount: ${rewardItem.amount}');
            // 每次点击增加道具数量
            GameDataManager().addRefreshCount(refreshCount);
            GameDataManager().addPenCount(penCount);
            GameDataManager().addHammerCount(hummberCount);
            GameDataManager().addLifeCount(lifeCount);
            // 记录观看广告
            GameDataManager().recordAdWatched();
            // 调用回调，通知奖励已领取
            widget.onRewardClaimed();
            // 设置已获得奖励标志
            _hasEarnedReward = true;
          },
          onAdClosed: () {
            print('广告已关闭');
            // 只有在获得奖励时才调用onAdClose()
            if (_hasEarnedReward) {
              widget.onAdClose();
              // 重置奖励标志
              _hasEarnedReward = false;
            }
            // 重新加载广告
            _initializeAds();
          },
          onAdFailedToShow: () {
            print('Failed to show rewarded ad');
            if (!isAdLoading && mounted) {
              _initializeAds();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white54,
        border: Border(
          bottom: BorderSide(color: Colors.black54, width: 0.67),
          top: BorderSide(color: Colors.black54, width: 0.67),
        ),
      ),
      padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemPlusWidget(
                title: "+$refreshCount",
                imgPath: "assets/images/btn/refresh.png",
              ),
              SizedBox(width: 2),
              ItemPlusWidget(
                title: "+$hummberCount",
                imgPath: "assets/images/btn/chuizi.png",
              ),
              SizedBox(width: 2),
              ItemPlusWidget(
                title: "+$penCount",
                imgPath: "assets/images/btn/pen.png",
              ),
              SizedBox(width: 2),
              ItemPlusWidget(
                title: "+$lifeCount",
                imgPath: "assets/images/btn/life.png",
              ),
              Spacer(),
              adBtn(),
            ],
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Watch an ad to receive special items!".tr,
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ),
          // 显示今日剩余广告次数
          Text(
            "${"today_ads_count".tr}: ${GameDataManager().getRemainingAdsToday()}/5",
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
