import 'dart:typed_data';

import 'buf.dart';

final class Var64Read {
	final int byteCount;
	final int _initialBits;
	const Var64Read._(this.byteCount, this._initialBits);
	factory Var64Read._parse(int value) {
		final byteCount = 8 - value.bitLength;
		final initialBits = value & (0x7f >>> byteCount);
		return Var64Read._(byteCount, initialBits);
	}
}

class Reader {
	final Buf _buf;
	final Endian endian;
	
	int _offset = 0;

	Reader(this._buf, {this.endian = Endian.big});

	Buf peek(int bytes) => _buf.view(_offset, bytes);

	Buf claim(int bytes, [bool clamp = false]) {
		if (bytes < 0) throw RangeError.value(bytes, 'bytes', 'Cannot claim a negative number of bytes');
		if (!clamp && _buf.length < _offset + bytes) {
			RangeError.checkValueInInterval(_offset + bytes, 0, _buf.length, 'bytes');
		}
		final result = _buf.view(_offset, bytes);
		_offset += bytes;
		return result;
	}

	int u8()                  => claim(1).data.getUint8( 0);
	int u16([Endian? endian]) => claim(2).data.getUint16(0, endian ?? this.endian);
	int u32([Endian? endian]) => claim(4).data.getUint32(0, endian ?? this.endian);
	int u64([Endian? endian]) => claim(8).data.getUint64(0, endian ?? this.endian);
	
	int i8()                  => claim(1).data.getInt8(  0);
	int i16([Endian? endian]) => claim(2).data.getInt16( 0, endian ?? this.endian);
	int i32([Endian? endian]) => claim(4).data.getInt32( 0, endian ?? this.endian);
	int i64([Endian? endian]) => claim(8).data.getInt64( 0, endian ?? this.endian);

	double f32([Endian? endian]) => claim(4).data.getFloat32(0, endian ?? this.endian);
	double f64([Endian? endian]) => claim(8).data.getFloat64(0, endian ?? this.endian);
	
	String utf8(int length)  => claim(length).utf8;
	String utf16(int length) => claim(length).align(2).utf16;
	String runes(int length) => claim(length).align(4).runes;

	void pad(int length) => claim(length - _offset);
	void skip(int length) => claim(length);

	Buf remaining() => _buf.view(_offset);
	int get length => _buf.length - _offset;

	Var64Read var64Init() => Var64Read._parse(u8());
	int Function() var64({bool signed = true}) {
		final value = u8();
		final byteCount = 8 - value.bitLength;
		final initialBits = value & (0x7f >>> byteCount);
		return () {
			var x = initialBits;

			if (byteCount == 8) return u64(Endian.little);

			final bytes = claim(byteCount).u8s;
			
			var offset = 7 - byteCount;
			for (var i = 0; i < byteCount; i++) {
				x |= bytes[i] << offset;
				offset += 8;
			}
			if (signed) x = (x >>> 1) ^ -(x & 1);
			
			return x;
		};
	}
	
	int varU64Extra(Var64Read init) {
		final byteCount = init.byteCount;
		var value = init._initialBits;

		if (byteCount == 8) return u64(Endian.little);

		final bytes = claim(byteCount).u8s;
		
		var offset = 7 - byteCount;
		for (var i = 0; i < byteCount; i++) {
			value |= bytes[i] << offset;
			offset += 8;
		}
		return value;
	}

	int varI64Extra(Var64Read init) {
		final x = varU64Extra(init);
		return (x >>> 1) ^ -(x & 1);
	}

	int varU64() {
	  final initial = var64Init();
	  return varU64Extra(initial);
	}

	int varI64() {
	  final initial = var64Init();
	  return varI64Extra(initial);
	}

	void Function() createRevertPoint() {
		final offset = _offset;
		return () => _offset = offset;
	}

  int get offset => _offset;
  Buf get read => _buf.view(0, _offset);
}

extension BufReader on Buf {
	Reader get reader => Reader(this);
}
