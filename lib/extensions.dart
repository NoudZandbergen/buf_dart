library;

import 'dart:typed_data';

import 'package:buf/buf.dart';

extension ByteBufferBuf on ByteBuffer {
  Buf get buf => Buf.raw(this, 0, lengthInBytes);
}

extension BytesBuilderBuf on BytesBuilder {
  Buf get buf => Buf(toBytes());
}

extension ByteDataBuf on ByteData {
  Buf get buf => Buf(this);
}

extension IntIterableBuf on Iterable<int> {
  Buf get buf => u8Buf;
  Buf get u8Buf => switch (this) {
    TypedData data => Buf(data),
    List<int> list => Buf(Uint8List.fromList(list)),
    _ => Buf(Uint8List.fromList(toList())),
  };
  Buf get u16Buf => switch (this) {
    List<int> list => Buf(Uint16List.fromList(list)),
    _ => Buf(Uint16List.fromList(toList())),
  };
  Buf get u32Buf => switch (this) {
    List<int> list => Buf(Uint32List.fromList(list)),
    _ => Buf(Uint32List.fromList(toList())),
  };
  Buf get u64Buf => switch (this) {
    List<int> list => Buf(Uint64List.fromList(list)),
    _ => Buf(Uint64List.fromList(toList())),
  };
  Buf get i8Buf => switch (this) {
    List<int> list => Buf(Int8List.fromList(list)),
    _ => Buf(Int8List.fromList(toList())),
  };
  Buf get i16Buf => switch (this) {
    List<int> list => Buf(Int16List.fromList(list)),
    _ => Buf(Int16List.fromList(toList())),
  };
  Buf get i32Buf => switch (this) {
    List<int> list => Buf(Int32List.fromList(list)),
    _ => Buf(Int32List.fromList(toList())),
  };
  Buf get i64Buf => switch (this) {
    List<int> list => Buf(Int64List.fromList(list)),
    _ => Buf(Int64List.fromList(toList())),
  };
}

extension DoubleIterableBuf on Iterable<double> {
  Buf get f32Buf => switch (this) {
    TypedData data => Buf(data),
    List<double> list => Buf(Float32List.fromList(list)),
    _ => Buf(Float32List.fromList(toList())),
  };
  Buf get f64Buf => switch (this) {
    TypedData data => Buf(data),
    List<double> list => Buf(Float64List.fromList(list)),
    _ => Buf(Float64List.fromList(toList())),
  };
}

extension StringBuf on String {
  Buf get buf => utf8Buf;
  Buf get utf8Buf => Buf.fromUtf8(this);
  Buf get utf16Buf => Buf.fromUtf16(this);
  Buf get runesBuf => Buf.fromRunes(this);
}
