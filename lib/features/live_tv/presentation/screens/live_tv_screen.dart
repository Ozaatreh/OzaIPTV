import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../design_system/components/channel_card.dart';
import '../../../../design_system/components/loading_states.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/spacing.dart';
import '../../../../domain/entities/channel_category.dart';

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

class LiveTvScreen extends ConsumerWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Live TV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter bar
          categoriesAsync.when(
            data: (categories) => _buildCategoryFilter(
              ref,
              categories,
              selectedCategory,
            ),
            loading: () => const SizedBox(height: 48),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Channel grid
          Expanded(
            child: channelsAsync.when(
              data: (channels) {
                final filtered = selectedCategory == null
                    ? channels
                    : channels
                        .where((c) => c.categoryId == selectedCategory)
                        .toList();

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.live_tv_outlined,
                    title: 'No channels found',
                    subtitle: 'Try selecting a different category',
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    mainAxisSpacing: AppSpacing.cardGapMedium,
                    crossAxisSpacing: AppSpacing.cardGapMedium,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final channel = filtered[index];
                    return ChannelCard(
                      name: channel.name,
                      logoUrl: channel.logoUrl,
                      isLive: channel.isLive,
                      onTap: () => context.push('/player/${channel.id}'),
                    );
                  },
                );
              },
              loading: () => const ChannelGridSkeleton(),
              error: (error, _) => ErrorStateWidget(
                message: error.toString(),
                onRetry: () => ref.invalidate(channelsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
    WidgetRef ref,
    List<ChannelCategory> categories,
    String? selectedId,
  ) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: 6,
        ),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedId == null;
            return FilterChip(
              label: const Text('All'),
              selected: isSelected,
              onSelected: (_) {
                ref.read(selectedCategoryProvider.notifier).state = null;
              },
              backgroundColor: AppColors.surfacePrimary,
              selectedColor: AppColors.accentGoldSubtle,
              checkmarkColor: AppColors.accentGold,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.accentGold
                    : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.accentGold
                    : AppColors.borderSubtle,
              ),
            );
          }

          final cat = categories[index - 1];
          final isSelected = selectedId == cat.id;
          return FilterChip(
            label: Text(cat.name),
            selected: isSelected,
            onSelected: (_) {
              ref.read(selectedCategoryProvider.notifier).state =
                  isSelected ? null : cat.id;
            },
            backgroundColor: AppColors.surfacePrimary,
            selectedColor: AppColors.accentGoldSubtle,
            checkmarkColor: AppColors.accentGold,
            labelStyle: TextStyle(
              color: isSelected
                  ? AppColors.accentGold
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.accentGold
                  : AppColors.borderSubtle,
            ),
          );
        },
      ),
    );
  }
}
