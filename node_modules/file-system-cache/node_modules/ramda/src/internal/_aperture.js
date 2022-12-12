var _slice = require('./_slice');

module.exports = function _aperture(n, list) {
  var idx = 0;
  var limit = list.length - (n - 1);
  var acc = new Array(limit >= 0 ? limit : 0);
  while (idx < limit) {
    acc[idx] = _slice(list, idx, idx + n);
    idx += 1;
  }
  return acc;
};
