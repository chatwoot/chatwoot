/* global self */
import { Decrypter } from 'aes-decrypter';
import { createTransferableMessage } from './bin-utils';

/**
 * Our web worker interface so that things can talk to aes-decrypter
 * that will be running in a web worker. the scope is passed to this by
 * webworkify.
 */
self.onmessage = function(event) {
  const data = event.data;
  const encrypted = new Uint8Array(
    data.encrypted.bytes,
    data.encrypted.byteOffset,
    data.encrypted.byteLength
  );
  const key = new Uint32Array(
    data.key.bytes,
    data.key.byteOffset,
    data.key.byteLength / 4
  );
  const iv = new Uint32Array(
    data.iv.bytes,
    data.iv.byteOffset,
    data.iv.byteLength / 4
  );

  /* eslint-disable no-new, handle-callback-err */
  new Decrypter(
    encrypted,
    key,
    iv,
    function(err, bytes) {
      self.postMessage(createTransferableMessage({
        source: data.source,
        decrypted: bytes
      }), [bytes.buffer]);
    }
  );
  /* eslint-enable */
};
