import window from 'global/window';

var atob = function atob(s) {
  return window.atob ? window.atob(s) : Buffer.from(s, 'base64').toString('binary');
};

export default function decodeB64ToUint8Array(b64Text) {
  var decodedString = atob(b64Text);
  var array = new Uint8Array(decodedString.length);

  for (var i = 0; i < decodedString.length; i++) {
    array[i] = decodedString.charCodeAt(i);
  }

  return array;
}