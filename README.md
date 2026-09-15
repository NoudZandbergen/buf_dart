# buf

A slice-oriented byte buffer over shared `ByteBuffer` storage.

`Buf` tracks a `[start, end)` range inside one backing buffer. Use `view` for
zero-copy sub-ranges, and `copy` when you need an independent buffer.

## Usage

```dart
import 'package:buf/buf.dart';

void main() {
  final buf = Buf.fromUtf8('hello');
  final slice = buf.view(1, 3);

  print(slice.utf8); // 'ell'
  print(slice.u8s);  // [101, 108, 108]
}
```

## Important behavior

**Shared memory.** `view` returns a new `Buf` over the same backing storage.
Mutations through one view are visible through every overlapping view. Use
`copied` or `copy` for an independent buffer.

**Typed views.** Accessors such as `u16s`, `i32s`, and `f64s` reinterpret bytes
using the platform's native endianness. When the byte `length` is not a multiple
of the element size, trailing bytes are silently ignored.

**Text helpers.** `fromUtf16` stores UTF-16 code units, not full UTF-16 byte
encoding. `fromRunes` stores Unicode code points as 32-bit integers.

**Alignment.** `aligned` and the `Align` extension round offsets to multiples of
a positive alignment size.

## Development

```bash
dart test
dart doc .
```
