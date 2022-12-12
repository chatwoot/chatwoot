var _typeof = require("@babel/runtime-corejs3/helpers/typeof")["default"];

var _WeakMap = require("@babel/runtime-corejs3/core-js/weak-map");

var _Symbol$replace = require("@babel/runtime-corejs3/core-js/symbol/replace");

var _reduceInstanceProperty = require("@babel/runtime-corejs3/core-js/instance/reduce");

var _Object$keys = require("@babel/runtime-corejs3/core-js/object/keys");

var _Object$create = require("@babel/runtime-corejs3/core-js/object/create");

var wrapNativeSuper = require("./wrapNativeSuper.js");

var getPrototypeOf = require("./getPrototypeOf.js");

var possibleConstructorReturn = require("./possibleConstructorReturn.js");

var inherits = require("./inherits.js");

function _wrapRegExp(re, groups) {
  module.exports = _wrapRegExp = function _wrapRegExp(re, groups) {
    return new BabelRegExp(re, undefined, groups);
  };

  module.exports["default"] = module.exports, module.exports.__esModule = true;

  var _RegExp = wrapNativeSuper(RegExp);

  var _super = RegExp.prototype;

  var _groups = new _WeakMap();

  function BabelRegExp(re, flags, groups) {
    var _this = _RegExp.call(this, re, flags);

    _groups.set(_this, groups || _groups.get(re));

    return _this;
  }

  inherits(BabelRegExp, _RegExp);

  BabelRegExp.prototype.exec = function (str) {
    var result = _super.exec.call(this, str);

    if (result) result.groups = buildGroups(result, this);
    return result;
  };

  BabelRegExp.prototype[_Symbol$replace] = function (str, substitution) {
    if (typeof substitution === "string") {
      var groups = _groups.get(this);

      return _super[_Symbol$replace].call(this, str, substitution.replace(/\$<([^>]+)>/g, function (_, name) {
        return "$" + groups[name];
      }));
    } else if (typeof substitution === "function") {
      var _this = this;

      return _super[_Symbol$replace].call(this, str, function () {
        var args = [];
        args.push.apply(args, arguments);

        if (_typeof(args[args.length - 1]) !== "object") {
          args.push(buildGroups(args, _this));
        }

        return substitution.apply(this, args);
      });
    } else {
      return _super[_Symbol$replace].call(this, str, substitution);
    }
  };

  function buildGroups(result, re) {
    var _context;

    var g = _groups.get(re);

    return _reduceInstanceProperty(_context = _Object$keys(g)).call(_context, function (groups, name) {
      groups[name] = result[g[name]];
      return groups;
    }, _Object$create(null));
  }

  return _wrapRegExp.apply(this, arguments);
}

module.exports = _wrapRegExp;
module.exports["default"] = module.exports, module.exports.__esModule = true;