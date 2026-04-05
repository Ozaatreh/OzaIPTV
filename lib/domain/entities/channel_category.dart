import 'package:equatable/equatable.dart';

/// Represents a channel category/group.
class ChannelCategory extends Equatable {
  const ChannelCategory({
    required this.id,
    required this.name,
    this.iconName,
    this.description,
    this.sortOrder = 0,
    this.channelCount = 0,
  });

  final String id;
  final String name;
  final String? iconName;
  final String? description;
  final int sortOrder;
  final int channelCount;

  @override
  List<Object?> get props => [id, name];
}
