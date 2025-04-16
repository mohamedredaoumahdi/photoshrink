import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBanner extends StatelessWidget {
  final BannerAd ad;

  const AdBanner({
    Key? key,
    required this.ad,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ad.size.height.toDouble(),
      width: ad.size.width.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: ad),
    );
  }
}
