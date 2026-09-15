import 'dart:typed_data';

import 'package:buf/buf.dart';
import 'package:test/test.dart';

void main() {
  group('Buf.raw', () {
    test('rejects out-of-range start and length', () {
      final buffer = Uint8List(4).buffer;

      expect(() => Buf.raw(buffer, -1, 1), throwsRangeError);
      expect(() => Buf.raw(buffer, 5, 0), throwsRangeError);
      expect(() => Buf.raw(buffer, 0, 5), throwsRangeError);
      expect(() => Buf.raw(buffer, 3, 2), throwsRangeError);
    });

    test('accepts valid ranges', () {
      final buf = Buf.raw(Uint8List.fromList([1, 2, 3, 4]).buffer, 1, 2);

      expect(buf.start, 1);
      expect(buf.length, 2);
      expect(buf.end, 3);
      expect(buf.u8s, [2, 3]);
    });
  });

  group('view / _subrange', () {
    late Buf buf;

    setUp(() {
      buf = Buf(Uint8List.fromList([10, 11, 12, 13, 14]));
    });

    test('views from positive offset with default length', () {
      final slice = buf.view(1);

      expect(slice.start, 1);
      expect(slice.length, 4);
      expect(slice.u8s, [11, 12, 13, 14]);
    });

    test('views from negative offset relative to end', () {
      final slice = buf.view(-2);

      expect(slice.start, 3);
      expect(slice.length, 2);
      expect(slice.u8s, [13, 14]);
    });

    test('supports explicit length and negative length', () {
      expect(buf.view(1, 2).u8s, [11, 12]);
      expect(buf.view(1, -1).u8s, [11, 12, 13]);
    });

    test('clamps offset and length by default', () {
      expect(buf.view(10).length, 0);
      expect(buf.view(0, 10).length, 5);
      expect(buf.view(3, 10).length, 2);
    });

    test('can disable clamping', () {
      expect(() => buf.view(10, null, false), throwsRangeError);
      expect(() => buf.view(0, 10, false), throwsRangeError);
    });

    test('shares backing storage with source', () {
      final slice = buf.view(1, 2);
      slice.u8s[0] = 99;

      expect(buf.u8s, [10, 99, 12, 13, 14]);
    });
  });

  group('copy', () {
    test('copied buffer is independent from source', () {
      final source = Buf(Uint8List.fromList([1, 2, 3]));
      final copy = source.copy();

      copy.u8s[0] = 9;

      expect(source.u8s, [1, 2, 3]);
      expect(copy.u8s, [9, 2, 3]);
    });

    test('copy respects view bounds', () {
      final source = Buf(Uint8List.fromList([1, 2, 3, 4, 5]));
      final copy = source.copy(1, 2);

      expect(copy.u8s, [2, 3]);
    });
  });

  group('copyTo / copyFrom', () {
    test('copies min of source and destination length', () {
      final source = Buf(Uint8List.fromList([1, 2, 3, 4]));
      final dest = Buf.init(2);

      expect(source.copyTo(dest), 2);
      expect(dest.u8s, [1, 2]);
    });

    test('copyFrom writes into this buffer', () {
      final source = Buf(Uint8List.fromList([7, 8, 9]));
      final dest = Buf.init(5);

      expect(dest.copyFrom(source), 3);
      expect(dest.u8s, [7, 8, 9, 0, 0]);
    });

    test('viewTo limits bytes copied from start', () {
      final source = Buf(Uint8List.fromList([1, 2, 3]));
      final dest = Buf.init(4);

      source.u8s.setAll(0, [5, 6, 7]);
      expect(source.copyTo(dest), 3);
      expect(dest.u8s, [5, 6, 7, 0]);
    });
  });

  group('margins', () {
    test('margins trims both sides via view', () {
      final buf = Buf(Uint8List.fromList([0, 1, 2, 3, 4, 5]));

      expect(buf.margins(1, 2).u8s, [1, 2, 3]);
    });

    test('margins rejects invalid margins', () {
      final buf = Buf(Uint8List.fromList([0, 1, 2, 3, 4, 5]));

      expect(() => buf.margins(-1, 0), throwsRangeError);
      expect(() => buf.margins(0, -1), throwsRangeError);
      expect(() => buf.margins(4, 3), throwsRangeError);
    });
  });

  group('typed views', () {
    test('u16s truncates misaligned byte length', () {
      final buf = Buf(Uint8List.fromList([0x01, 0x02, 0x03]));

      expect(buf.u16s.length, 1);
      expect(buf.u16s[0], 0x0201);
    });
  });

  group('copyPadded / copyResized', () {
    test('copyPadded inserts padding around content', () {
      final source = Buf(Uint8List.fromList([1, 2, 3]));
      final padded = source.copyPadded(2, 3);

      expect(padded.length, 8);
      expect(padded.u8s, [0, 0, 1, 2, 3, 0, 0, 0]);
    });

    test('copyResized truncates or zero-fills', () {
      final source = Buf(Uint8List.fromList([1, 2, 3, 4]));

      expect(source.copyResized(2).u8s, [1, 2]);
      expect(source.copyResized(6).u8s, [1, 2, 3, 4, 0, 0]);
    });
  });

  group('clear', () {
    test('clears visible range without affecting siblings in shared buffer', () {
      final backing = Uint8List.fromList([1, 2, 3, 4, 5]);
      final buf = Buf.raw(backing.buffer, 1, 3);

      buf.clear();

      expect(backing, [1, 0, 0, 0, 5]);
    });
  });
}
