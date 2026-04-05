import 'package:equatable/equatable.dart';

class FavoriteItem extends Equatable {
  const FavoriteItem({
    required this.channelId,
    required this.addedAt,
    this.sortOrder = 0,
  });

  final String channelId;
  final DateTime addedAt;
  final int sortOrder;

  @override
  List<Object?> get props => [channelId];
}
