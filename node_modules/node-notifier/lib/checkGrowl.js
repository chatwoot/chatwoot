var net = require('net');

var hasGrowl = false;
module.exports = function(growlConfig, cb) {
  if (typeof cb === 'undefined') {
    cb = growlConfig;
    growlConfig = {};
  }
  if (hasGrowl) return cb(null, hasGrowl);
  var port = growlConfig.port || 23053;
  var host = growlConfig.host || 'localhost';
  var socket = net.connect(port, host);
  socket.setTimeout(100);

  socket.once('connect', function() {
    socket.end();
    cb(null, true);
  });

  socket.once('error', function() {
    socket.end();
    cb(null, false);
  });
};
