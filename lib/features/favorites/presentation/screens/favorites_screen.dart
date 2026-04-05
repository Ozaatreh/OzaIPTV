import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers.dart';
import '../../../../data/repositories/favorites_repository_impl.dart';
import '../../../../design_system/components/channel_card.dart';
import '../../../../design_system/components/loading_states.dart';
import '../../../../design_system/tokens/colors.dart';
import '../../../../design_system/tokens/spacing.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final channelsAsync = ref.watch(channelsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          favoritesAsync.maybeWhen(
            data: (favs) => favs.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _confirmClear(context, ref),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: favoritesAsync.when(
        data: (favorites) {
          if (favorites.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.favorite_outline_rounded,
              title: 'No favorites yet',
              subtitle:
                  'Long press on a channel to add it to your favorites',
            );
          }

          return channelsAsync.when(
            data: (channels) {
              final favoriteChannels = favorites
                  .map((fav) {
                    try {
                      return channels.firstWhere(
                        (c) => c.id == fav.channelId,
                      );
                    } catch (_) {
                      return null;
                    }
                  })
                  .whereType<dynamic>()
                  .toList();

              if (favoriteChannels.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.favorite_outline_rounded,
                  title: 'No favorites yet',
                  subtitle: 'Channels you favorite will appear here',
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
                itemCount: favoriteChannels.length,
                itemBuilder: (context, index) {
                  final channel = favoriteChannels[index];
                  return ChannelCard(
                    name: channel.name as String,
                    logoUrl: channel.logoUrl as String?,
                    isLive: channel.isLive as bool,
                    isFavorite: true,
                    onTap: () =>
                        context.push('/player/${channel.id}'),
                    onLongPress: () =>
                        _removeFavorite(context, ref, channel.id as String),
                  );
                },
              );
            },
            loading: () => const ChannelGridSkeleton(),
            error: (e, _) => ErrorStateWidget(message: e.toString()),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGold),
        ),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
      ),
    );
  }

  Future<void> _removeFavorite(
    BuildContext context,
    WidgetRef ref,
    String channelId,
  ) async {
    await ref.read(favoritesRepositoryProvider).removeFavorite(channelId);
    ref.invalidate(favoritesProvider);
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Favorites'),
        content: const Text(
          'Remove all channels from your favorites?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(favoritesRepositoryProvider)
                  .clearFavorites();
              ref.invalidate(favoritesProvider);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
