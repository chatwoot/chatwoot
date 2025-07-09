import QUnit from 'qunit';
import decodeB64ToUint8Array from '../src/decode-b64-to-uint8-array.js';

QUnit.module('decodeB64ToUint8Array');

// slightly modified version of m3u8 test
// 'parses Widevine #EXT-X-KEY attributes and attaches to manifest'
QUnit.test('can decode', function(assert) {
  const b64 = 'AAAAPnBzc2gAAAAA7e+LqXnWSs6jyCfc1R0h7QAAAB4iFnNoYWthX2NlYzJmNjRhYTc4OTBhMTFI49yVmwY';
  const result = decodeB64ToUint8Array(b64);

  assert.deepEqual(result.byteLength, 62, 'decoded');
});
