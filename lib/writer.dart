import 'dart:typed_data';

import 'buf.dart';

final class Var64Write {
	final int byteCount;
	final int _followingBits;
	const Var64Write._(this.byteCount, this._followingBits);
}

class Writer {
	Buf _buf;
	int _offset = 0;
	final Endian endian;
	final bool growable;

	int get size => _offset;
	Buf get result => _buf.viewTo(_offset);

	Writer({this.endian = Endian.big, int length = 256, this.growable = true}) : _buf = Buf.init(length);
	Writer.into(this._buf, {this.endian = Endian.big, this.growable = false});

	@pragma('vm:prefer-inline')
	void _resize(int minSize, [bool exact = false]) {
	  final curSize = _buf.length;
    if (!growable) {
      if (minSize > curSize) {
        throw Exception('Writer is not growable and minSize is greater than the current size');
      } else {
        return;
      }
    }
		if (exact) {
			if (curSize == minSize) return;
			_buf = _buf.copyResized(minSize);
		} else {
			final newSize = 1 << ((minSize - 1).bitLength);
			if (curSize >= minSize && curSize <= newSize) return;
			_buf = _buf.copyResized(newSize);
		}
	}

	@pragma('vm:prefer-inline')
	Buf _peek(int length, [bool exact = false]) {
		_resize(_offset + length, exact);
		return _buf.view(_offset, length, false);
	}

	Buf peek(int length, [bool exact = false]) {
		if (length < 0) throw ArgumentError('Cannot view a negative amount of bytes');
		return _peek(length, exact);
	}

	@pragma('vm:prefer-inline')
	void _bump(int count) {
		_offset += count;
	}

	void bump(int count) {
		if (count < 0) throw ArgumentError('Cannot bump a negative amount of bytes');
		_bump(count);
	}

	Buf reserve(int count, [bool exact = false]) {
		if (count < 0) throw ArgumentError('Cannot reserve a negative amount of bytes');
		final result = _peek(count, exact);
		_bump(count);
		return result;
	}

	void u8( int value                  ) => reserve(1).data.setUint8( 0, value);
	void u16(int value, [Endian? endian]) => reserve(2).data.setUint16(0, value, endian ?? this.endian);
	void u32(int value, [Endian? endian]) => reserve(4).data.setUint32(0, value, endian ?? this.endian);
	void u64(int value, [Endian? endian]) => reserve(8).data.setUint64(0, value, endian ?? this.endian);

	void i8( int value                  ) => reserve(1).data.setInt8( 0, value);
	void i16(int value, [Endian? endian]) => reserve(2).data.setInt16(0, value, endian ?? this.endian);
	void i32(int value, [Endian? endian]) => reserve(4).data.setInt32(0, value, endian ?? this.endian);
	void i64(int value, [Endian? endian]) => reserve(8).data.setInt64(0, value, endian ?? this.endian);
	
	void f32(double value, [Endian? endian]) => reserve(4).data.setFloat32(0, value, endian ?? this.endian);
	void f64(double value, [Endian? endian]) => reserve(8).data.setFloat64(0, value, endian ?? this.endian);

	void add(Buf buf, [bool exact = false]) => reserve(buf.length, exact).copyFrom(buf);
	void utf8(String value) => add(Buf.fromUtf8(value));
	void chars(String value) => add(Buf.fromRunes(value));

	Var64Write varU64Init(int value) {
		if (value < 0 || value > 0xffffffffffffff) { // Catch all byteCount = 8 cases early without the operation, because it does not handle negative numbers the way we want.
			u8(0);
			return Var64Write._(8, value);
		}
		final byteCount = (value.bitLength - 1) ~/ 7; // This only works for 0 because -1 ~/ 7 is 0 in dart
		final leadingBits = 7 - byteCount; // Without the upper if statement, this could return -1 if bytecount is 8.
		final lsb = value & (0x7f >>> byteCount);
		final msb = value >>> leadingBits;
		u8(0x80 >> byteCount | lsb);
		return Var64Write._(byteCount, msb);
	}

	Var64Write varI64Init(int value) => varU64Init((value >> 63) ^ (value << 1));

	void var64Extra(Var64Write init) {
		final bytes = reserve(init.byteCount).u8s;
		var value = init._followingBits;
		for (var i = 0; i < init.byteCount; i++) {
			bytes[i] = value;
			value >>= 8;
		}
	}

	void varU64(int value) {
		final init = varU64Init(value);
		var64Extra(init);
	}

	void varI64(int value) {
		final init = varI64Init(value);
		var64Extra(init);
	}

	Writer split(int length) => Writer.into(reserve(length));

  void Function(void Function(Writer) write) writeLater(int length) {
    final offset = _offset;
    bump(length);
    return (callback) {
      final resume = _offset;
      _offset = offset;
      callback(Writer.into(_buf.view(_offset, length), growable: false));
      _offset = resume;
    };
  }

	int Function() trackGrowth() {
		final currentSize = size;
		return () => size - currentSize;
	}

	void Function() createRevertPoint() {
		final offset = _offset;
		return ([bool exact = false]) {
			_offset = offset;
			_resize(_offset, exact);
		};
	}

	/// Resets the writer to offset 0, and then moves [buf] to the beginning of the writer.
	void rebase(Buf buf) {
		_offset = 0;
		_resize(buf.length);
		_buf.copyFrom(buf);
	}
}

extension GetWriter on Buf {
	Writer get writer => Writer.into(this);

	static Buf written(void Function(Writer writer) write) {
		final writer = Writer();
		write(writer);
		return writer.result;
	}
}
