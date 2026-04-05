/// Domain layer — all entities and repository abstractions.
library;

export 'entities/app_settings.dart';
export 'entities/app_user.dart';
export 'entities/channel.dart';
export 'entities/channel_category.dart';
export 'entities/diagnostics_snapshot.dart';
export 'entities/epg_program.dart';
export 'entities/favorite_item.dart';
export 'entities/playback_session.dart';
export 'entities/stream_source.dart';
export 'entities/watch_history_item.dart';

export 'repositories/channel_repository.dart';
export 'repositories/epg_repository.dart';
export 'repositories/favorites_repository.dart';
export 'repositories/history_repository.dart';
export 'repositories/settings_repository.dart';
