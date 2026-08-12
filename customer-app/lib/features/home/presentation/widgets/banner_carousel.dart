import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/banner.dart';
import '../../../../providers/providers.dart';

class BannerCarousel extends ConsumerStatefulWidget {
  const BannerCarousel({super.key});

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;
  Timer? _timer;

  void _autoPlay(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      _page = (_page + 1) % count;
      _controller.animateToPage(
        _page,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTap(AppBanner b) {
    // category banner → filter the menu by that category.
    if (b.actionType == 'category' && b.actionValue != null) {
      ref.read(selectedCategoryProvider.notifier).state = b.actionValue;
    }
    // product / url actions can be wired later (needs url_launcher / product fetch).
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bannersProvider);
    return async.maybeWhen(
      orElse: () => const SizedBox(height: 8),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox(height: 8);
        _autoPlay(banners.length);
        return Column(
          children: [
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: _controller,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final b = banners[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => _onTap(b),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CachedNetworkImage(
                          imageUrl: b.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, __) => Container(color: AppColors.brandSurface),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.brandSurface,
                            child: const Center(child: Text('🍹', style: TextStyle(fontSize: 40))),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.brand : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
