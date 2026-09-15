library;

import 'dart:typed_data' show Uint8List;

import 'package:buf/buf.dart';
import 'package:buf/reader.dart';
import 'package:buf/writer.dart';

final _mask = BigInt.from(0xff);
final _neg1 = BigInt.from(-1);

extension BigIntBuf on BigInt {
  BigInt get zigzag => (this << 1) ^ (isNegative ? _neg1 : BigInt.zero);

  BigInt get zagzig => (this >> 1) ^ -(this & BigInt.one);

  Buf get ubuf {
    final bytes = Uint8List((bitLength + 7) ~/ 8);
    var n = this;
    for (var i = bytes.length - 1; i >= 0; i--) {
      bytes[i] = (n & _mask).toInt();
      n = n >> 8;
    }
    return Buf(bytes);
  }

  Buf get ibuf => zigzag.ubuf;
}

extension BufBigInt on Buf {
  BigInt get bigUint {
    return u8s.fold(BigInt.zero, (bigint, byte) {
      return (bigint << 8) | BigInt.from(byte);
    });
  }

  BigInt get bigInt => bigUint.zagzig;
}

extension WriteBigInt on Writer {
  void bigUint(BigInt value, [int? length]) {
    final trueLength = (value.bitLength + 7) ~/ 8;
    if (length == null) {
      length = trueLength;
      varU64(length);
    } else if (length < trueLength) {
      throw ArgumentError('BigInt $value cannot be stored in $length bytes');
    }
    final bytes = reserve(length).u8s;
    for (var i = bytes.length - 1; i >= 0; i--) {
      bytes[i] = (value & _mask).toInt();
      value = value >> 8;
    }
  }
  void bigInt(BigInt value, [int? length]) => bigUint(value.zigzag, length);
}

extension ReadBigInt on Reader {
  BigInt readBigUint([int? length]) => claim(length ?? varU64()).bigUint;
  BigInt readBigInt([int? length]) => claim(length ?? varU64()).bigInt;
}
