import 'package:flutter/material.dart';
import 'package:flutter_tencentad/flutter_tencentad.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wxx_cubia/util/huuua_config.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<HomeBanner> {
  FlutterTencentAdBiddingController _bidding =
      new FlutterTencentAdBiddingController();

  NativeAd? nativeAd;
  bool isNativeAdLoaded = false;
  bool isTencentBannerLoaded = false;
  bool hasShownAd = false; // 标记是否已经展示了某个广告

  @override
  void initState() {
    super.initState();
    // 同时启动两个广告的加载
    _loadNativeAd();
    // 腾讯广告会在bannerview构建时自动加载，这里不需要额外调用
  }

  @override
  void dispose() {
    nativeAd?.dispose();
    super.dispose();
  }

  void _loadNativeAd() {
    nativeAd = NativeAd(
      adUnitId: HuuuaConfig.instance.getAdmobBannerId(
        admob_type.admob_native,
      ), // 测试广告单元 ID，请替换为您自己的
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small, // small 或 medium
      ),
      factoryId: null,
      request: AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          print('$NativeAd loaded.');
          isNativeAdLoaded = true;
          // 竞量逻辑：如果还没有展示广告，优先展示第一个加载完成的
          if (!hasShownAd) {
            hasShownAd = true;
            setState(() {});
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$NativeAd failedToLoad: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  Widget admobNativeAdView() {
    if (nativeAd != null && isNativeAdLoaded) {
      return Container(
        height: 120, // 根据你的原生广告模板设置合适的高度
        width: double.infinity, // 宽度通常设置为撑满
        alignment: Alignment.center,
        child: AdWidget(ad: nativeAd!),
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    // 竞量逻辑：优先展示先加载完成的广告
    if (isNativeAdLoaded && !isTencentBannerLoaded) {
      return admobNativeAdView();
    } else if (isTencentBannerLoaded && !isNativeAdLoaded) {
      return bannerview();
    } else if (isNativeAdLoaded && isTencentBannerLoaded) {
      if (HuuuaConfig.instance.flavorstype == flavors_type.taptap) {
        return bannerview();
      }
      // 如果两个都加载完成，优先展示AdMob原生广告（可以根据需求调整优先级）
      return admobNativeAdView();
    } else {
      // 两个都还没加载完成，显示占位符或默认展示腾讯广告
      return bannerview();
    }
  }

  Widget bannerview() {
    return Container(
      height: 60,
      width: Get.width,
      color: Colors.blue.withOpacity(0.7),
      child: FlutterTencentad.bannerAdView(
        //android广告id
        androidId: "7370443604961170",
        //ios广告id
        iosId: "4320180143447033",
        //广告宽 单位dp
        viewWidth: Get.width,
        //广告高  单位dp   宽高比应该为6.4:1
        viewHeight: 60,
        //下载二次确认弹窗 默认false
        downloadConfirm: true,
        //是否开启竞价 默认不开启
        isBidding: true,
        //竞价结果回传
        bidding: _bidding,
        // 广告回调
        callBack: FlutterTencentadBannerCallBack(
          onShow: () {
            print("Banner广告显示");
            isTencentBannerLoaded = true;
            // // 竞量逻辑：如果还没有展示广告，优先展示第一个加载完成的
            if (!hasShownAd) {
              hasShownAd = true;
              setState(() {});
            }
          },
          onFail: (code, message) {
            print("Banner广告错误 $code $message");
          },
          onClose: () {
            print("Banner广告关闭");
          },
          onExpose: () {
            print("Banner广告曝光");
          },
          onClick: () {
            print("Banner广告点击");
          },
          onECPM: (ecpmLevel, ecpm) {
            print("Banner广告竞价  ecpmLevel=$ecpmLevel  ecpm=$ecpm");
            //规则 自己根据业务处理
            if (ecpm > 0) {
              //竞胜出价，类型为Integer
              //最大竞败方出价，类型为Integer
              _bidding.biddingResult(
                FlutterTencentBiddingResult().success(ecpm, 0),
              );
            } else {
              //竞胜方出价（单位：分），类型为Integer
              //优量汇广告竞败原因 FlutterTencentAdBiddingLossReason
              //竞胜方渠道ID FlutterTencentAdADNID
              _bidding.biddingResult(
                FlutterTencentBiddingResult().fail(
                  ecpm,
                  FlutterTencentAdBiddingLossReason.LOW_PRICE,
                  FlutterTencentAdADNID.othoerADN,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
