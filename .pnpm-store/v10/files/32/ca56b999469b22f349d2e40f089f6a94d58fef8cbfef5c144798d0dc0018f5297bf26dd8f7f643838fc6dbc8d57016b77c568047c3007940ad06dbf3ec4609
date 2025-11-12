// see docs/hlse.md for instructions on how test data was generated
import QUnit from 'qunit';
import {unpad} from 'pkcs7';
import sinon from 'sinon';
import {decrypt, Decrypter, AsyncStream} from '../src';

// see docs/hlse.md for instructions on how test data was generated
const stringFromBytes = function(bytes) {
  let result = '';

  for (let i = 0; i < bytes.length; i++) {
    result += String.fromCharCode(bytes[i]);
  }
  return result;
};

QUnit.module('Decryption');
QUnit.test('decrypts a single AES-128 with PKCS7 block', function(assert) {
  const key = new Uint32Array([0, 0, 0, 0]);
  const initVector = key;
  // the string "howdy folks" encrypted
  const encrypted = new Uint8Array([
    0xce, 0x90, 0x97, 0xd0,
    0x08, 0x46, 0x4d, 0x18,
    0x4f, 0xae, 0x01, 0x1c,
    0x82, 0xa8, 0xf0, 0x67
  ]);

  assert.deepEqual(
    'howdy folks',
    stringFromBytes(unpad(decrypt(encrypted, key, initVector))),
    'decrypted with a byte array key'
  );
});

QUnit.test('decrypts multiple AES-128 blocks with CBC', function(assert) {
  const key = new Uint32Array([0, 0, 0, 0]);
  const initVector = key;
  // the string "0123456789abcdef01234" encrypted
  const encrypted = new Uint8Array([
    0x14, 0xf5, 0xfe, 0x74,
    0x69, 0x66, 0xf2, 0x92,
    0x65, 0x1c, 0x22, 0x88,
    0xbb, 0xff, 0x46, 0x09,

    0x0b, 0xde, 0x5e, 0x71,
    0x77, 0x87, 0xeb, 0x84,
    0xa9, 0x54, 0xc2, 0x45,
    0xe9, 0x4e, 0x29, 0xb3
  ]);

  assert.deepEqual(
    '0123456789abcdef01234',
    stringFromBytes(unpad(decrypt(encrypted, key, initVector))),
    'decrypted multiple blocks'
  );
});

QUnit.test(
  'verify that the deepcopy works by doing two decrypts in the same test',
  function(assert) {
    const key = new Uint32Array([0, 0, 0, 0]);
    const initVector = key;
    // the string "howdy folks" encrypted
    const pkcs7Block = new Uint8Array([
      0xce, 0x90, 0x97, 0xd0,
      0x08, 0x46, 0x4d, 0x18,
      0x4f, 0xae, 0x01, 0x1c,
      0x82, 0xa8, 0xf0, 0x67
    ]);

    assert.deepEqual(
      'howdy folks',
      stringFromBytes(unpad(decrypt(pkcs7Block, key, initVector))),
      'decrypted with a byte array key'
    );

    // the string "0123456789abcdef01234" encrypted
    const cbcBlocks = new Uint8Array([
      0x14, 0xf5, 0xfe, 0x74,
      0x69, 0x66, 0xf2, 0x92,
      0x65, 0x1c, 0x22, 0x88,
      0xbb, 0xff, 0x46, 0x09,

      0x0b, 0xde, 0x5e, 0x71,
      0x77, 0x87, 0xeb, 0x84,
      0xa9, 0x54, 0xc2, 0x45,
      0xe9, 0x4e, 0x29, 0xb3
    ]);

    assert.deepEqual(
      '0123456789abcdef01234',
      stringFromBytes(unpad(decrypt(cbcBlocks, key, initVector))),
      'decrypted multiple blocks'
    );

  }
);

QUnit.module('Incremental Processing', {
  beforeEach() {
    this.clock = sinon.useFakeTimers();
  },
  afterEach() {
    this.clock.restore();
  }
});

QUnit.test('executes a callback after a timeout', function(assert) {
  const asyncStream = new AsyncStream();
  let calls = '';

  asyncStream.push(function() {
    calls += 'a';
  });

  this.clock.tick(asyncStream.delay);
  assert.equal(calls, 'a', 'invoked the callback once');
  this.clock.tick(asyncStream.delay);
  assert.equal(calls, 'a', 'only invoked the callback once');
});

QUnit.test('executes callback in series', function(assert) {
  const asyncStream = new AsyncStream();
  let calls = '';

  asyncStream.push(function() {
    calls += 'a';
  });
  asyncStream.push(function() {
    calls += 'b';
  });

  this.clock.tick(asyncStream.delay);
  assert.equal(calls, 'a', 'invoked the first callback');
  this.clock.tick(asyncStream.delay);
  assert.equal(calls, 'ab', 'invoked the second');
});

QUnit.module('Incremental Decryption', {
  beforeEach() {
    this.clock = sinon.useFakeTimers();
  },
  afterEach() {
    this.clock.restore();
  }
});

QUnit.test('asynchronously decrypts a 4-word block', function(assert) {
  const key = new Uint32Array([0, 0, 0, 0]);
  const initVector = key;
  // the string "howdy folks" encrypted
  const encrypted = new Uint8Array([0xce, 0x90, 0x97, 0xd0,
    0x08, 0x46, 0x4d, 0x18,
    0x4f, 0xae, 0x01, 0x1c,
    0x82, 0xa8, 0xf0, 0x67]);
  let decrypted;
  const decrypter = new Decrypter(
    encrypted,
    key,
    initVector,
    function(error, result) {
      if (error) {
        throw new Error(error);
      }
      decrypted = result;
    }
  );

  assert.ok(!decrypted, 'asynchronously decrypts');
  this.clock.tick(decrypter.asyncStream_.delay * 2);

  assert.ok(decrypted, 'completed decryption');
  assert.deepEqual(
    'howdy folks',
    stringFromBytes(decrypted),
    'decrypts and unpads the result'
  );
});

QUnit.test('breaks up input greater than the step value', function(assert) {
  const encrypted = new Int32Array(Decrypter.STEP + 4);
  let done = false;
  const decrypter = new Decrypter(
    encrypted,
    new Uint32Array(4),
    new Uint32Array(4),
    function() {
      done = true;
    }
  );

  this.clock.tick(decrypter.asyncStream_.delay * 2);
  assert.ok(!done, 'not finished after two ticks');

  this.clock.tick(decrypter.asyncStream_.delay);
  assert.ok(done, 'finished after the last chunk is decrypted');
});
