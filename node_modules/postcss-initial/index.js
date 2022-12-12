var postcss = require('postcss');
var makeFallbackFunction = require('./lib/rules-fabric');

module.exports = postcss.plugin('postcss-initial', function (opts) {
  opts = opts || {};
  opts.reset = opts.reset || 'all';
  opts.replace = opts.replace || false;
  var getFallback = makeFallbackFunction(opts.reset === 'inherited');
  var getPropPrevTo = function (prop, decl) {
    var foundPrev = false;
    decl.parent.walkDecls(function (child) {
      if (child.prop === decl.prop && child.value !== decl.value) {
        foundPrev = true;
      }
    });
    return foundPrev;
  };
  return function (css) {
    css.walkDecls(function (decl) {
      if (!/\binitial\b/.test(decl.value)) {
        return;
      }
      var fallBackRules = getFallback(decl.prop, decl.value);
      if (fallBackRules.length === 0) return;
      fallBackRules.forEach(function (rule) {
        if ( !getPropPrevTo(decl.prop, decl) ) {
          decl.cloneBefore(rule);
        }
      });
      if (opts.replace === true) {
        decl.remove();
      }
    });
  };
});
