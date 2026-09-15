/// A slice-oriented byte buffer over shared [ByteBuffer] storage.
library;

import 'dart:typed_data';
import 'dart:convert' as convert;

import 'align.dart';

export 'align.dart';

enum AlignMode {
  // Always copy the buffer even if the start is already aligned.
  alwaysCopy,
  // Maybe copy the buffer if the start is not aligned.
  copy,
  // Shrink the buffer so the start aligns to the next multiple of [size].
  shrink,
  // Throw an error if the start is not aligned. Shrinks the end to align.
  shrinkEnd,
  // Throw an error if the start or end are not aligned.
  error,
}

/// A view into a contiguous byte range within a shared [ByteBuffer].
///
/// [Buf] tracks a `[start, end)` range inside one backing buffer. Multiple
/// [Buf] instances can overlap and share memory; writes through one view are
/// visible through every overlapping view.
///
/// Use [view] for zero-copy sub-ranges. Use [copy] or [copied] when you need an
/// independent buffer.
///
/// Typed accessors ([u16s], [i32s], [f64s], and so on) reinterpret the same
/// bytes using the platform's native endianness. When [length] is not a multiple
/// of the element size, the trailing bytes are silently ignored.
final class Buf {
  /// An empty buffer.
  static final Buf empty = Buf.init(0);

  /// The backing [ByteBuffer].
  final ByteBuffer _buf;

  /// Absolute start offset in the backing [ByteBuffer].
  final int start;

  /// Number of bytes in this view.
  final int length;

  /// Absolute end offset in the backing [ByteBuffer] (exclusive).
  int get end => start + length;

  /// Allocates a new zero-filled buffer of [length] bytes.
  Buf.init(int length) : this(Uint8List(length));

  /// Wraps the bytes exposed by [typed], including its offset and length.
  Buf(TypedData typed)
    : _buf = typed.buffer
    , start = typed.offsetInBytes
    , length = typed.lengthInBytes;

  /// Wraps [length] bytes in [buf] starting at [start].
  ///
  /// Throws a [RangeError] when [start] or [length] fall outside [buf].
  Buf.raw(this._buf, this.start, this.length) {
    RangeError.checkValueInInterval(start, 0, _buf.lengthInBytes);
    RangeError.checkValueInInterval(length, 0, _buf.lengthInBytes - start);
  }

  /// Wraps the half-open range `[start, end)` in [buf].
  Buf.rawRange(ByteBuffer buf, int start, int end, [bool clamp = true])
    : this.raw(buf, start, clamp && end < start ? 0 : end - start);

  /// Encodes [string] as UTF-8 bytes.
  Buf.fromUtf8(String string) : this(convert.utf8.encode(string));

  /// Stores [string] as UTF-16 code units (not full UTF-16 byte encoding).
  Buf.fromUtf16(String string) : this(Uint16List.fromList(string.codeUnits));

  /// Stores Unicode code points from [string] as 32-bit integers.
  Buf.fromRunes(String string) : this(Uint32List.fromList(string.runes.toList()));

  /// A [ByteData] view over this range.
  ByteData get data => _buf.asByteData(start, length);

  /// An unsigned 8-bit view over this range.
  Uint8List get u8s => _buf.asUint8List(start, length);

  /// An unsigned 16-bit view; uses [length] ~/ 2 elements.
  Uint16List get u16s => _buf.asUint16List(start, length ~/ 2);

  /// An unsigned 32-bit view; uses [length] ~/ 4 elements.
  Uint32List get u32s => _buf.asUint32List(start, length ~/ 4);

  /// An unsigned 64-bit view; uses [length] ~/ 8 elements.
  Uint64List get u64s => _buf.asUint64List(start, length ~/ 8);

  /// A signed 8-bit view over this range.
  Int8List get i8s => _buf.asInt8List(start, length);

  /// A signed 16-bit view; uses [length] ~/ 2 elements.
  Int16List get i16s => _buf.asInt16List(start, length ~/ 2);

  /// A signed 32-bit view; uses [length] ~/ 4 elements.
  Int32List get i32s => _buf.asInt32List(start, length ~/ 4);

  /// A signed 64-bit view; uses [length] ~/ 8 elements.
  Int64List get i64s => _buf.asInt64List(start, length ~/ 8);

  /// A 32-bit floating-point view; uses [length] ~/ 4 elements.
  Float32List get f32s => _buf.asFloat32List(start, length ~/ 4);

  /// A 64-bit floating-point view; uses [length] ~/ 8 elements.
  Float64List get f64s => _buf.asFloat64List(start, length ~/ 8);

  /// Decodes this range as UTF-8 text.
  String get utf8 => convert.utf8.decode(u8s);

  /// Decodes [u16s] as UTF-16 code units.
  String get utf16 => String.fromCharCodes(u16s);

  /// Decodes [u32s] as Unicode code points.
  String get runes => String.fromCharCodes(u32s);

  @pragma('vm:prefer-inline')
  (int offset, int length) _subrange([int signedOffset = 0, int? span, bool clamp = true]) {
    var absStart = signedOffset < 0 ? end + signedOffset : start + signedOffset;
    if (clamp) absStart = absStart.clamp(start, end);

    var absStop = switch (span) {
      null => end,
      < 0 => end + span,
      _ => absStart + span,
    };
    if (clamp) absStop = absStop.clamp(absStart, end);

    return (absStart, absStop - absStart);
  }

  /// Sets every byte in this view to zero.
  ///
  /// Only affects bytes in `[start, end)`; other bytes in the shared backing
  /// buffer are unchanged.
  void clear() => u8s.fillRange(0, length, 0);

  /// Returns a zero-copy sub-range of this view.
  ///
  /// [offset] is relative to [start]. Negative values count from [end].
  /// When [length] is omitted, the view runs to [end]. Negative [length]
  /// counts backward from [end].
  ///
  /// By default, out-of-range [offset] and [length] values are clamped. When
  /// [clamp] is `false`, invalid ranges throw a [RangeError].
  Buf view([int offset = 0, int? length, bool clamp = true]) {
    (offset, length) = _subrange(offset, length, clamp);
    return Buf.raw(_buf, offset, length);
  }

  /// Returns a view of at most [length] bytes from the start of this view.
  Buf viewTo(int length) => view(0, length, true);

  /// Returns the largest aligned sub-range of this view.
  ///
  /// The result starts at [start.alignCeil] and ends at [end.alignFloor] for
  /// the given [size]. [size] must be positive.
  ///
  /// Throws an [ArgumentError] when [size] is not positive.
  Buf align(int size, {AlignMode mode = .shrink}) {
    if (size < 1) {
      throw ArgumentError.value(size, 'size', 'must be at least 1');
    }
    
    final alignedStart = start.alignCeil(size);

    switch (mode) {
      case .alwaysCopy || .copy:
        final cutLength = length.alignFloor(size);
        var buf = view(0, cutLength);
        if (mode == .alwaysCopy || start != alignedStart) {
          return buf.copied;
        }
        return buf;
      case .shrink:
        return Buf.rawRange(_buf, alignedStart, end.alignFloor(size));
      case .shrinkEnd:
        if (start != alignedStart) {
          throw RangeError.value(alignedStart, 'start', 'must be aligned to $size');
        }
        return Buf.rawRange(_buf, alignedStart, end.alignFloor(size));
      case .error:
        if (start != alignedStart) {
          throw RangeError.value(alignedStart, 'start', 'must be aligned to $size');
        }
        final alignedEnd = end.alignFloor(size);
        if (end != alignedEnd) {
          throw RangeError.value(alignedEnd, 'end', 'must be aligned to $size');
        }
        return this;
    }
  }

  /// Trims [left] bytes from the start and [right] bytes from the end.
  ///
  /// Throws a [RangeError] when [left] or [right] are negative, or when their
  /// sum exceeds [length].
  Buf margins(int left, [int right = 0]) {
    RangeError.checkNotNegative(left, 'left');
    RangeError.checkNotNegative(right, 'right');
    if (left + right > length) {
      throw RangeError.range(left + right, 0, length, 'left + right');
    }
    return view(left, length - left - right);
  }

  /// Returns an independent copy of the bytes in this view.
  Buf get copied => Buf(u8s.sublist(0));

  /// Returns an independent copy of a sub-range of this view.
  Buf copy([int offset = 0, int? length, bool clamp = true]) => view(offset, length, clamp).copied;

  /// Copies bytes from this view into [buf].
  ///
  /// Copies `min(this.length, buf.length)` bytes starting at each view's start.
  /// Returns the number of bytes copied.
  int copyTo(Buf buf) {
    final view = viewTo(buf.length);
    buf.u8s.setAll(0, view.u8s);
    return view.length;
  }

  /// Copies bytes from [buf] into this view.
  ///
  /// Returns the number of bytes copied.
  int copyFrom(Buf buf) => buf.copyTo(this);

  /// Returns a new buffer with [left] zero bytes before and [right] zero bytes
  /// after a copy of this view.
  Buf copyPadded(int left, [int right = 0]) => Buf.init(left + length + right)..view(left).copyFrom(this);

  /// Returns a new buffer of [length] bytes containing a copy of this view.
  ///
  /// Truncates or zero-fills when [length] differs from this view's [length].
  Buf copyResized(int length) => Buf.init(length)..copyFrom(this);

  /// Returns a copy in a buffer [length] bytes larger than this view.
  Buf copyExtended(int length) => copyResized(this.length + length);

  @override
  String toString() => 'Buf(start: $start, length: $length, capacity: ${_buf.lengthInBytes})';

  static Buf concatTyped(Iterable<TypedData> chunks) {
    final totalLength = chunks.fold(0, (sum, chunk) => sum + chunk.lengthInBytes);
    final buf = Buf.init(totalLength);
    var offset = 0;
    for (final chunk in chunks) {
      buf.view(offset).copyFrom(Buf(chunk));
      offset += chunk.lengthInBytes;
    }
    return buf;
  }
}
