import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class GlassOnlyLoaderOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? lottieAsset;
  final double scrimOpacity;
  final double blurSigma;
  final double cardOpacity;

  const GlassOnlyLoaderOverlay({
    super.key,
    this.title = 'Sedang memproses...',
    this.subtitle = 'Mohon tunggu sebentar.',
    this.lottieAsset = 'assets/animations/loading_face.json',
    this.scrimOpacity = 0.22,
    this.blurSigma = 12.0,
    this.cardOpacity = 0.04,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardWidth = (screenW * 0.6).clamp(300.0, 420.0);

    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black.withOpacity(scrimOpacity),
          dismissible: false,
        ),
        Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Opacity(
              opacity: 0.8,
              child: Container(
                height: 380,
                width: cardWidth,
                padding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xff818CF8).withOpacity(0.2),
                      const Color(0xffDB2777).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: lottieAsset != null && lottieAsset!.isNotEmpty
                          ? Lottie.asset(
                              lottieAsset!,
                              width: 200,
                              height: 200,
                              repeat: true,
                            )
                          : SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.5,
                                valueColor: AlwaysStoppedAnimation(
                                    Colors.cyanAccent.shade200),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.78), fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: cardWidth * 0.6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          value: null,
                          backgroundColor: Colors.white.withOpacity(0.03),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.cyanAccent.shade200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
