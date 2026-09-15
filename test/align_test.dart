import 'package:buf/buf.dart';
import 'package:test/test.dart';

void main() {
  group('alignFloor', () {
    test('rounds down to the nearest multiple', () {
      expect(0.alignFloor(4), 0);
      expect(1.alignFloor(4), 0);
      expect(3.alignFloor(4), 0);
      expect(4.alignFloor(4), 4);
      expect(7.alignFloor(4), 4);
      expect(8.alignFloor(4), 8);
    });

    test('works with alignment size 1', () {
      expect(5.alignFloor(1), 5);
      expect((-3).alignFloor(1), -3);
    });

    test('uses floor division for negative values', () {
      expect((-1).alignFloor(4), 0);
      expect((-4).alignFloor(4), -4);
      expect((-5).alignFloor(4), -4);
    });
  });

  group('alignCeil', () {
    test('rounds up to the nearest multiple', () {
      expect(0.alignCeil(4), 0);
      expect(1.alignCeil(4), 4);
      expect(3.alignCeil(4), 4);
      expect(4.alignCeil(4), 4);
      expect(5.alignCeil(4), 8);
      expect(8.alignCeil(4), 8);
    });

    test('works with alignment size 1', () {
      expect(5.alignCeil(1), 5);
      expect((-3).alignCeil(1), -3);
    });

    test('follows truncating division for negative values', () {
      expect((-1).alignCeil(4), 0);
      expect((-4).alignCeil(4), 0);
      expect((-5).alignCeil(4), 0);
    });
  });

  group('alignRound', () {
    test('rounds to the nearest multiple', () {
      expect(0.alignRound(4), 0);
      expect(1.alignRound(4), 0);
      expect(2.alignRound(4), 4);
      expect(3.alignRound(4), 4);
      expect(4.alignRound(4), 4);
      expect(5.alignRound(4), 4);
      expect(6.alignRound(4), 8);
      expect(8.alignRound(4), 8);
    });

    test('works with alignment size 1', () {
      expect(5.alignRound(1), 5);
      expect((-3).alignRound(1), -3);
    });

    test('rounds to nearest multiple for odd alignment (n = 3)', () {
      expect(0.alignRound(3), 0);
      expect(1.alignRound(3), 0);
      expect(2.alignRound(3), 3);
      expect(3.alignRound(3), 3);
      expect(4.alignRound(3), 3);
      expect(5.alignRound(3), 6);
      expect(6.alignRound(3), 6);
      expect(7.alignRound(3), 6);
      expect(8.alignRound(3), 9);
    });

    test('rounds to nearest multiple for odd alignment (n = 5)', () {
      expect(0.alignRound(5), 0);
      expect(1.alignRound(5), 0);
      expect(2.alignRound(5), 0);
      expect(3.alignRound(5), 5);
      expect(4.alignRound(5), 5);
      expect(5.alignRound(5), 5);
      expect(6.alignRound(5), 5);
      expect(7.alignRound(5), 5);
      expect(8.alignRound(5), 10);
      expect(9.alignRound(5), 10);
      expect(10.alignRound(5), 10);
    });

    test('rounds half up for even alignment tie cases', () {
      expect(2.alignRound(4), 4);
    });
  });

  group('relationships', () {
    test('floor and ceil bracket the original value for positive n', () {
      for (final value in [0, 1, 3, 4, 7, 8, 15]) {
        expect(value.alignFloor(4), lessThanOrEqualTo(value));
        expect(value.alignCeil(4), greaterThanOrEqualTo(value));
        expect(value.alignFloor(4), lessThanOrEqualTo(value.alignCeil(4)));
      }
    });

    test('already aligned values are unchanged', () {
      for (final value in [0, 4, 8, 12]) {
        expect(value.alignFloor(4), value);
        expect(value.alignCeil(4), value);
        expect(value.alignRound(4), value);
      }
    });
  });

  group('invalid alignment', () {
    test('rejects non-positive alignment', () {
      expect(() => 1.alignFloor(0), throwsArgumentError);
      expect(() => 1.alignCeil(0), throwsArgumentError);
      expect(() => 1.alignRound(0), throwsArgumentError);
      expect(() => 1.alignFloor(-4), throwsArgumentError);
    });
  });
}
