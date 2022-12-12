'use strict';

/* eslint global-require: 0 */

var fs = require('fs');
var path = require('path');

var test = require('tape');

// delete es-abstract from the require cache
Object.keys(require.cache)
  .filter(function (x) { return /\/es-abstract\//.test(x); })
  .forEach(function (x) { delete require.cache[x]; });

test('main', function (t) {
  require('../');
  t.ok(true, 'parses');
  t.end();
});

test('targets', function (t) {
  var targetsPath = path.join(__dirname, '../target');
  var targets = fs.readdirSync(targetsPath);

  targets.sort(function (a, b) {
    if (/es5\.js$/.test(a)) {
      return 1;
    }
    if (/es5\.js$/.test(b)) {
      return 1;
    }
    return a.localeCompare(b);
  });
  t.comment('importing targets: ' + targets.join(','));
  targets.forEach(function (target) {
    t.test(target, function (st) {
      require(path.join(targetsPath, target));
      st.ok(true, 'parses');
      st.end();
    });
  });
  t.end();
});
