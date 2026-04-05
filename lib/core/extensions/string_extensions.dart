/// String utility extensions.
extension StringX on String {
  /// Capitalize the first letter.
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Truncate with ellipsis.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}…';
  }

  /// Convert "some_slug_name" to "Some Slug Name".
  String get slugToTitle {
    return split('_')
        .where((s) => s.isNotEmpty)
        .map((s) => s.capitalized)
        .join(' ');
  }
}

/// Nullable string extension.
extension NullableStringX on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}
