var _slice = require('./_slice');

module.exports = function dropLastWhile(pred, list) {
  var idx = list.length - 1;
  while (idx >= 0 && pred(list[idx])) {
    idx -= 1;
  }
  return _slice(list, 0, idx + 1);
};
