/* eslint-disable object-shorthand */

import {pad, unpad} from '../src/pkcs7.js';
import QUnit from 'qunit';

const pkcs7 = {pad, unpad};

QUnit.module('pkcs7');

QUnit.test('pads empty buffers', function(assert) {
  assert.expect(1);

  const result = pkcs7.unpad(pkcs7.pad(new Uint8Array([])));

  assert.deepEqual(
    new Uint8Array(result, result.byteOffset, result.byteLength),
    new Uint8Array(0),
    'accepts an empty buffer'
  );
});

QUnit.test('pads non-empty buffers', function(assert) {

  let i = 16;

  assert.expect(i * 3);

  while (i--) {
    // build the test buffer
    const buffer = new Uint8Array(i + 1);
    let result;

    result = pkcs7.pad(buffer);
    assert.equal(result.length % 16, 0, 'padded length is a multiple of 16');
    assert.equal(result.slice(-1)[0], 16 - ((i + 1) % 16), 'appended the correct value');

    result = pkcs7.unpad(result);

    assert.deepEqual(
      new Uint8Array(result, result.byteOffset, result.byteLength),
      buffer,
      'padding is reversible'
    );
  }
});

QUnit.test('works on buffers greater than sixteen bytes', function(assert) {
  const buffer = new Uint8Array(16 * 3 + 9);

  assert.expect(2);

  assert.equal(
    pkcs7.pad(buffer).length - buffer.length,
    16 - 9,
    'adds the correct amount of padding'
  );
  const result = pkcs7.unpad(pkcs7.pad(buffer));

  assert.deepEqual(
    new Uint8Array(result, result.byteOffset, result.byteLength),
    buffer,
    'is reversible'
  );
});
