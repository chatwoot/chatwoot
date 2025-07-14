var window = require('global/window');
// TODO: use vhs-utils here

var atob = (s) => window.atob ? window.atob(s) : Buffer.from(s, 'base64').toString('binary');

var base64ToUint8Array = function(base64) {
  var decoded = atob(base64);
  var uint8Array = new Uint8Array(new ArrayBuffer(decoded.length));

  for (var i = 0; i < decoded.length; i++) {
    uint8Array[i] = decoded.charCodeAt(i);
  }

  return uint8Array;
};

module.exports = base64ToUint8Array;
