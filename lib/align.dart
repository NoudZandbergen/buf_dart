library;

/// Alignment helpers for rounding integers to multiples of [n].
extension Align on int {
  /// Rounds [this] down to the largest multiple of [n] that is less than or
  /// equal to [this].
  ///
  /// Equivalent to `(this ~/ n) * n`. For non-negative values this is the same
  /// as mathematical floor division to a multiple; for negative values it
  /// follows Dart truncating division (`~/`), not mathematical floor.
  ///
  /// Example: `7.alignFloor(4)` returns `4`; `3.alignFloor(4)` returns `0`.
  int alignFloor(int n) {
    final div = this ~/ n;
    return div * n;
  }

  /// Rounds [this] to the nearest multiple of [n].
  ///
  /// Uses the usual integer rounding formula `(this + n ~/ 2) ~/ n * n`, which
  /// picks the closest multiple. When two multiples are equally close, the larger
  /// one is chosen (round half up).
  ///
  /// For even [n], values exactly halfway between multiples — such as `2` when
  /// [n] is `4` — round up. For odd [n], no integer sits exactly on a midpoint
  /// (for example `1.5` for [n] `3`), so every value has a single nearest
  /// multiple with no tie case.
  ///
  /// Example: `3.alignRound(4)` returns `4`; `5.alignRound(4)` returns `4`.
  int alignRound(int n) {
    final div = (this + n ~/ 2) ~/ n;
    return div * n;
  }

  /// Rounds [this] up to the smallest multiple of [n] that is greater than or
  /// equal to [this].
  ///
  /// Equivalent to `(this + n - 1) ~/ n * n` for non-negative values. Already
  /// aligned values are unchanged. For negative values the result follows Dart
  /// truncating division (`~/`), not mathematical ceiling.
  ///
  /// Example: `3.alignCeil(4)` returns `4`; `4.alignCeil(4)` returns `4`.
  int alignCeil(int n) {
    final div = (this + n - 1) ~/ n;
    return div * n;
  }
}
