import QUnit from 'qunit';
import {
  bytesToString,
  stringToBytes,
  toUint8,
  concatTypedArrays,
  toHexString,
  toBinaryString,
  bytesToNumber,
  numberToBytes,
  bytesMatch
} from '../src/byte-helpers.js';
import window from 'global/window';

const arrayNames = [];
const BigInt = window.BigInt;

[
  'Array',
  'Int8Array',
  'Uint8Array',
  'Uint8ClampedArray',
  'Int16Array',
  'Uint16Array',
  'Int32Array',
  'Uint32Array',
  'Float32Array',
  'Float64Array'
].forEach(function(name) {
  if (window[name]) {
    arrayNames.push(name);
  }
});

QUnit.module('bytesToString');

const testString = 'hello竜';
const testBytes = toUint8([
  // h
  0x68,
  // e
  0x65,
  // l
  0x6c,
  // l
  0x6c,
  // o
  0x6f,
  // 竜
  0xe7, 0xab, 0x9c
]);

const rawBytes = toUint8([0x47, 0x40, 0x00, 0x10, 0x00, 0x00, 0xb0, 0x0d, 0x00, 0x01]);

QUnit.test('should function as expected', function(assert) {
  arrayNames.forEach(function(name) {
    const testObj = name === 'Array' ? testBytes : new window[name](testBytes);

    assert.equal(bytesToString(testObj), testString, `testString work as a string arg with ${name}`);
    assert.equal(bytesToString(new window[name]()), '', `empty ${name} returns empty string`);
  });

  assert.equal(bytesToString(), '', 'undefined returns empty string');
  assert.equal(bytesToString(null), '', 'null returns empty string');
  assert.equal(bytesToString(stringToBytes(testString)), testString, 'stringToBytes -> bytesToString works');
});

QUnit.module('stringToBytes');

QUnit.test('should function as expected', function(assert) {
  assert.deepEqual(stringToBytes(testString), testBytes, 'returns an array of bytes');
  assert.deepEqual(stringToBytes(), toUint8(), 'empty array for undefined');
  assert.deepEqual(stringToBytes(null), toUint8(), 'empty array for null');
  assert.deepEqual(stringToBytes(''), toUint8(), 'empty array for empty string');
  assert.deepEqual(stringToBytes(10), toUint8([0x31, 0x30]), 'converts numbers to strings');
  assert.deepEqual(stringToBytes(bytesToString(testBytes)), testBytes, 'bytesToString -> stringToBytes works');
  assert.deepEqual(stringToBytes(bytesToString(rawBytes), true), rawBytes, 'equal to original with raw bytes mode');
  assert.notDeepEqual(stringToBytes(bytesToString(rawBytes)), rawBytes, 'without raw byte mode works, not equal');
});

QUnit.module('toUint8');

QUnit.test('should function as expected', function(assert) {
  const tests = {
    undef: {
      data: undefined,
      expected: new Uint8Array()
    },
    null: {
      data: null,
      expected: new Uint8Array()
    },
    string: {
      data: 'foo',
      expected: new Uint8Array()
    },
    NaN: {
      data: NaN,
      expected: new Uint8Array()
    },
    object: {
      data: {},
      expected: new Uint8Array()
    },
    number: {
      data: 0x11,
      expected: new Uint8Array([0x11])
    }
  };

  Object.keys(tests).forEach(function(name) {
    const {data, expected} = tests[name];
    const result = toUint8(data);

    assert.ok(result instanceof Uint8Array, `obj is a Uint8Array for ${name}`);
    assert.deepEqual(result, expected, `data is as expected for ${name}`);
  });

  arrayNames.forEach(function(name) {
    const testObj = name === 'Array' ? testBytes : new window[name](testBytes);
    const uint = toUint8(testObj);

    assert.ok(uint instanceof Uint8Array && uint.length > 0, `converted ${name} to Uint8Array`);
  });

});

QUnit.module('concatTypedArrays');

QUnit.test('should function as expected', function(assert) {
  const tests = {
    undef: {
      data: concatTypedArrays(),
      expected: toUint8([])
    },
    empty: {
      data: concatTypedArrays(toUint8([])),
      expected: toUint8([])
    },
    single: {
      data: concatTypedArrays([0x01]),
      expected: toUint8([0x01])
    },
    array: {
      data: concatTypedArrays([0x01], [0x02]),
      expected: toUint8([0x01, 0x02])
    },
    uint: {
      data: concatTypedArrays(toUint8([0x01]), toUint8([0x02])),
      expected: toUint8([0x01, 0x02])
    },
    buffer: {
      data: concatTypedArrays(toUint8([0x01]).buffer, toUint8([0x02]).buffer),
      expected: toUint8([0x01, 0x02])
    },
    manyarray: {
      data: concatTypedArrays([0x01], [0x02], [0x03], [0x04]),
      expected: toUint8([0x01, 0x02, 0x03, 0x04])
    },
    manyuint: {
      data: concatTypedArrays(toUint8([0x01]), toUint8([0x02]), toUint8([0x03]), toUint8([0x04])),
      expected: toUint8([0x01, 0x02, 0x03, 0x04])
    }
  };

  Object.keys(tests).forEach(function(name) {
    const {data, expected} = tests[name];

    assert.ok(data instanceof Uint8Array, `obj is a Uint8Array for ${name}`);
    assert.deepEqual(data, expected, `data is as expected for ${name}`);
  });
});

QUnit.module('toHexString');
QUnit.test('should function as expected', function(assert) {
  assert.equal(toHexString(0xFF), 'ff', 'works with single value');
  assert.equal(toHexString([0xFF, 0xaa]), 'ffaa', 'works with array');
  assert.equal(toHexString(toUint8([0xFF, 0xaa])), 'ffaa', 'works with uint8');
  assert.equal(toHexString(toUint8([0xFF, 0xaa]).buffer), 'ffaa', 'works with buffer');
  assert.equal(toHexString(toUint8([0xFF, 0xaa, 0xbb]).subarray(1, 3)), 'aabb', 'works with subarray');
  assert.equal(toHexString([0x01, 0x02, 0x03]), '010203', 'works with single digits');
});

QUnit.module('toBinaryString');
QUnit.test('should function as expected', function(assert) {
  const ff = '11111111';
  const aa = '10101010';
  const bb = '10111011';
  const zerof = '00001111';
  const one = '00000001';
  const zero = '00000000';
  const fzero = '11110000';

  assert.equal(toBinaryString(0xFF), ff, 'works with single value');
  assert.equal(toBinaryString([0xFF, 0xaa]), ff + aa, 'works with array');
  assert.equal(toBinaryString(toUint8([0xFF, 0xbb])), ff + bb, 'works with uint8');
  assert.equal(toBinaryString(toUint8([0xFF, 0xaa]).buffer), ff + aa, 'works with buffer');
  assert.equal(toBinaryString(toUint8([0xFF, 0xaa, 0xbb]).subarray(1, 3)), aa + bb, 'works with subarray');
  assert.equal(toBinaryString([0x0F, 0x01, 0xF0, 0x00]), zerof + one + fzero + zero, 'works with varying digits digits');
});

QUnit.module('bytesToNumber');
QUnit.test('sanity', function(assert) {
  assert.equal(bytesToNumber(0xFF), 0xFF, 'single value');
  assert.equal(bytesToNumber([0xFF, 0x01]), 0xFF01, 'works with array');
  assert.equal(bytesToNumber(toUint8([0xFF, 0xbb])), 0xFFBB, 'works with uint8');
  assert.equal(bytesToNumber(toUint8([0xFF, 0xaa]).buffer), 0xFFAA, 'works with buffer');
  assert.equal(bytesToNumber(toUint8([0xFF, 0xaa, 0xbb]).subarray(1, 3)), 0xAABB, 'works with subarray');
});
QUnit.test('unsigned and littleEndian work', function(assert) {
  // works with any number of bits
  assert.equal(bytesToNumber([0xFF]), 0xFF, 'u8');
  assert.equal(bytesToNumber([0xFF, 0xAA]), 0xFFAA, 'u16');
  assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB]), 0xFFAABB, 'u24');
  assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB, 0xCC]), 0xFFAABBCC, 'u32');
  assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB, 0xCC, 0xDD]), 0xFFAABBCCDD, 'u40');
  assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE]), 0xFFAABBCCDDEE, 'u48');

  assert.equal(bytesToNumber([0xFF], {le: true}), 0xFF, 'u8 le');
  assert.equal(bytesToNumber([0xFF, 0xAA], {le: true}), 0xAAFF, 'u16 le');
  assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB], {le: true}), 0xBBAAFF, 'u24 le');
  assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB, 0xCC], {le: true}), 0xCCBBAAFF, 'u32 le');
  assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB, 0xCC, 0xDD], {le: true}), 0xDDCCBBAAFF, 'u40 le');
  assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE], {le: true}), 0xEEDDCCBBAAFF, 'u48 le');

  if (BigInt) {
    assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0x99]), 0xFFAABBCCDDEE99, 'u56');
    assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0x99, 0x88]), 0xFFAABBCCDDEE9988, 'u64');
    assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0x99], {le: true}), 0x99EEDDCCBBAAFF, 'u56 le');
    assert.equal(bytesToNumber([0xFF, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0x99, 0x88], {le: true}), 0x8899EEDDCCBBAAFF, 'u64 le');
  }
});

QUnit.test('signed and littleEndian work', function(assert) {
  assert.equal(bytesToNumber([0xF0], {signed: true}), -16, 'i8');
  assert.equal(bytesToNumber([0x80, 0x70], {signed: true}), -32656, 'i16');
  assert.equal(bytesToNumber([0x80, 0x70, 0x9f], {signed: true}), -8359777, 'i24');
  assert.equal(bytesToNumber([0x80, 0x70, 0x9f, 0xFF], {signed: true}), -2140102657, 'i32');
  assert.equal(bytesToNumber([0x80, 0x70, 0x9f, 0xFF, 0x10], {signed: true}), -547866280176, 'i40');
  assert.equal(bytesToNumber([0x80, 0x70, 0x9f, 0xFF, 0x10, 0x89], {signed: true}), -140253767724919, 'i48');

  assert.equal(bytesToNumber([0xF0], {signed: true, le: true}), -16, 'i8 le');
  assert.equal(bytesToNumber([0x80, 0x70], {signed: true, le: true}), 0x7080, 'i16 le');
  assert.equal(bytesToNumber([0x80, 0x70, 0x9f], {signed: true, le: true}), -6328192, 'i24 le');
  assert.equal(bytesToNumber([0x80, 0x70, 0x9f, 0xFF], {signed: true, le: true}), -6328192, 'i32 le');
  assert.equal(bytesToNumber([0x80, 0x70, 0x9f, 0xFF, 0x10], {signed: true, le: true}), 73008115840, 'i40 le');
  assert.equal(bytesToNumber([0x80, 0x70, 0x9f, 0xFF, 0x10, 0x89], {signed: true, le: true}), -130768875589504, 'i48 le');

  if (BigInt) {
    assert.equal(bytesToNumber([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], {signed: true}), -1, 'i56');
    assert.equal(bytesToNumber([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], {signed: true}), -1, 'i64');
    assert.equal(bytesToNumber([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], {signed: true, le: true}), -1, 'i56 le');
    assert.equal(bytesToNumber([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], {signed: true, le: true}), -1, 'i64 le');
  }
});

QUnit.module('numberToBytes');

QUnit.test('unsigned negative and positive', function(assert) {
  assert.deepEqual(numberToBytes(), toUint8([0x00]), 'no bytes');
  assert.deepEqual(numberToBytes(0xFF), toUint8([0xFF]), 'u8');
  assert.deepEqual(numberToBytes(0xFFaa), toUint8([0xFF, 0xaa]), 'u16');
  assert.deepEqual(numberToBytes(0xFFaabb), toUint8([0xFF, 0xaa, 0xbb]), 'u24');
  assert.deepEqual(numberToBytes(0xFFaabbcc), toUint8([0xFF, 0xaa, 0xbb, 0xcc]), 'u32');
  assert.deepEqual(numberToBytes(0xFFaabbccdd), toUint8([0xFF, 0xaa, 0xbb, 0xcc, 0xdd]), 'u40');
  assert.deepEqual(numberToBytes(0xFFaabbccddee), toUint8([0xFF, 0xaa, 0xbb, 0xcc, 0xdd, 0xee]), 'u48');

  assert.deepEqual(numberToBytes(-16), toUint8([0xF0]), 'negative to u8');
  assert.deepEqual(numberToBytes(-32640), toUint8([0x80, 0x80]), 'negative to u16');
  assert.deepEqual(numberToBytes(-3264062), toUint8([0xce, 0x31, 0xc2]), 'negative to u24');
  assert.deepEqual(numberToBytes(-2139062144), toUint8([0x80, 0x80, 0x80, 0x80]), 'negative to u32');
  assert.deepEqual(numberToBytes(-3139062144), toUint8([0xff, 0x44, 0xe5, 0xb6, 0x80]), 'negative u40');
  assert.deepEqual(numberToBytes(-3139062144444), toUint8([0xfd, 0x25, 0x21, 0x50, 0xe2, 0x44]), 'negative u48');

  if (BigInt) {
    assert.deepEqual(numberToBytes(BigInt('0xFFaabbccddee99')), toUint8([0xFF, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0x99]), 'u56');
    assert.deepEqual(numberToBytes(BigInt('0xFFaabbccddee9988')), toUint8([0xFF, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0x99, 0x88]), 'u64');
    assert.deepEqual(numberToBytes(BigInt('-31390621444448812')), toUint8([0x90, 0x7a, 0x65, 0x67, 0x86, 0x5d, 0xd4]), 'negative to u56');
    assert.deepEqual(numberToBytes(BigInt('-9187201950435737472')), toUint8([0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), 'u64');
  }
});

QUnit.test('unsigned littleEndian negative and positive', function(assert) {
  assert.deepEqual(numberToBytes(0xFF, {le: true}), toUint8([0xFF]), 'u8');
  assert.deepEqual(numberToBytes(0xFFaa, {le: true}), toUint8([0xaa, 0xFF]), 'u16');
  assert.deepEqual(numberToBytes(0xFFaabb, {le: true}), toUint8([0xbb, 0xaa, 0xFF]), 'u24');
  assert.deepEqual(numberToBytes(0xFFaabbcc, {le: true}), toUint8([0xcc, 0xbb, 0xaa, 0xff]), 'u32');
  assert.deepEqual(numberToBytes(0xFFaabbccdd, {le: true}), toUint8([0xdd, 0xcc, 0xbb, 0xaa, 0xff]), 'u40');
  assert.deepEqual(numberToBytes(0xFFaabbccddee, {le: true}), toUint8([0xee, 0xdd, 0xcc, 0xbb, 0xaa, 0xff]), 'u48');

  assert.deepEqual(numberToBytes(-16, {le: true}), toUint8([0xF0]), 'negative to u8');
  assert.deepEqual(numberToBytes(-32640, {le: true}), toUint8([0x80, 0x80]), 'negative to u16');
  assert.deepEqual(numberToBytes(-3264062, {le: true}), toUint8([0xc2, 0x31, 0xce]), 'negative to u24');
  assert.deepEqual(numberToBytes(-2139062144, {le: true}), toUint8([0x80, 0x80, 0x80, 0x80]), 'negative to u32');
  assert.deepEqual(numberToBytes(-3139062144, {le: true}), toUint8([0x80, 0xb6, 0xe5, 0x44, 0xff]), 'negative u40');
  assert.deepEqual(numberToBytes(-3139062144444, {le: true}), toUint8([0x44, 0xe2, 0x50, 0x21, 0x25, 0xfd]), 'negative u48');

  if (BigInt) {
    assert.deepEqual(numberToBytes(BigInt('0xFFaabbccddee99'), {le: true}), toUint8([0x99, 0xee, 0xdd, 0xcc, 0xbb, 0xaa, 0xff]), 'u56');
    assert.deepEqual(numberToBytes(BigInt('0xFFaabbccddee9988'), {le: true}), toUint8([0x88, 0x99, 0xee, 0xdd, 0xcc, 0xbb, 0xaa, 0xff]), 'u64');
    assert.deepEqual(numberToBytes(BigInt('-31390621444448812'), {le: true}), toUint8([0xd4, 0x5d, 0x86, 0x67, 0x65, 0x7a, 0x90]), 'negative to u56');
    assert.deepEqual(numberToBytes(BigInt('-9187201950435737472'), {le: true}), toUint8([0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80]), 'u64');
  }
});

QUnit.module('bytesMatch');
QUnit.test('should function as expected', function(assert) {
  assert.equal(bytesMatch(), false, 'no a or b bytes, false');
  assert.equal(bytesMatch(null, []), false, 'no a bytes, false');
  assert.equal(bytesMatch([]), false, 'no b bytes, false');
  assert.equal(bytesMatch([0x00], [0x00, 0x02]), false, 'not enough bytes');
  assert.equal(bytesMatch([0x00], [0x00], {offset: 1}), false, 'not due to offset');
  assert.equal(bytesMatch([0xbb, 0xaa], [0xaa]), false, 'bytes do not match');
  assert.equal(bytesMatch([0xaa], [0xaa], {mask: [0x10]}), false, 'bytes do not match due to mask');
  assert.equal(bytesMatch([0xaa], [0xaa]), true, 'bytes match');
  assert.equal(bytesMatch([0xbb, 0xaa], [0xbb]), true, 'bytes match more a');
  assert.equal(bytesMatch([0xbb, 0xaa], [0xaa], {offset: 1}), true, 'bytes match with offset');
  assert.equal(bytesMatch([0xaa], [0x20], {mask: [0x20]}), true, 'bytes match with mask');
  assert.equal(bytesMatch([0xbb, 0xaa], [0x20], {mask: [0x20], offset: 1}), true, 'bytes match with mask and offset');
  assert.equal(bytesMatch([0xbb, 0xaa, 0xaa], [0x20, 0x20], {mask: [0x20, 0x20], offset: 1}), true, 'bytes match with many masks and offset');
});
