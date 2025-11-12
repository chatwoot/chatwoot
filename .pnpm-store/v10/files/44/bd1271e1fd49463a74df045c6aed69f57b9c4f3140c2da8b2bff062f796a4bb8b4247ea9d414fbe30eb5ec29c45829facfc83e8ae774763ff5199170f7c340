import window from 'global/window';

const atob = (s) => window.atob ? window.atob(s) : Buffer.from(s, 'base64').toString('binary');

export default function decodeB64ToUint8Array(b64Text) {
  const decodedString = atob(b64Text);
  const array = new Uint8Array(decodedString.length);

  for (let i = 0; i < decodedString.length; i++) {
    array[i] = decodedString.charCodeAt(i);
  }
  return array;
}
