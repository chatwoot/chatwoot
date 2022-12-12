"use strict";

require("core-js/modules/es.array.slice.js");

require("core-js/modules/es.object.freeze.js");

require("core-js/modules/es.symbol.js");

require("core-js/modules/es.symbol.description.js");

require("core-js/modules/es.symbol.iterator.js");

require("core-js/modules/es.array.from.js");

require("core-js/modules/es.function.name.js");

require("core-js/modules/es.regexp.exec.js");

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.GlobalsStore = void 0;

require("core-js/modules/es.array.iterator.js");

require("core-js/modules/es.object.to-string.js");

require("core-js/modules/es.set.js");

require("core-js/modules/es.string.iterator.js");

require("core-js/modules/web.dom-collections.iterator.js");

require("core-js/modules/es.array.concat.js");

require("core-js/modules/es.object.keys.js");

require("core-js/modules/es.object.assign.js");

require("core-js/modules/es.object.entries.js");

require("core-js/modules/web.dom-collections.for-each.js");

var _utilDeprecate = _interopRequireDefault(require("util-deprecate"));

var _tsDedent = _interopRequireDefault(require("ts-dedent"));

var _args = require("./args");

var _getValuesFromArgTypes = require("./csf/getValuesFromArgTypes");

var _templateObject;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _slicedToArray(arr, i) { return _arrayWithHoles(arr) || _iterableToArrayLimit(arr, i) || _unsupportedIterableToArray(arr, i) || _nonIterableRest(); }

function _nonIterableRest() { throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _iterableToArrayLimit(arr, i) { var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"]; if (_i == null) return; var _arr = []; var _n = true; var _d = false; var _s, _e; try { for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"] != null) _i["return"](); } finally { if (_d) throw _e; } } return _arr; }

function _arrayWithHoles(arr) { if (Array.isArray(arr)) return arr; }

function _toConsumableArray(arr) { return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread(); }

function _nonIterableSpread() { throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _iterableToArray(iter) { if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter); }

function _arrayWithoutHoles(arr) { if (Array.isArray(arr)) return _arrayLikeToArray(arr); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } }

function _createClass(Constructor, protoProps, staticProps) { if (protoProps) _defineProperties(Constructor.prototype, protoProps); if (staticProps) _defineProperties(Constructor, staticProps); Object.defineProperty(Constructor, "prototype", { writable: false }); return Constructor; }

function _taggedTemplateLiteral(strings, raw) { if (!raw) { raw = strings.slice(0); } return Object.freeze(Object.defineProperties(strings, { raw: { value: Object.freeze(raw) } })); }

var setUndeclaredWarning = (0, _utilDeprecate.default)(function () {}, (0, _tsDedent.default)(_templateObject || (_templateObject = _taggedTemplateLiteral(["\n    Setting a global value that is undeclared (i.e. not in the user's initial set of globals\n    or globalTypes) is deprecated and will have no effect in 7.0.\n  "]))));

var GlobalsStore = /*#__PURE__*/function () {
  function GlobalsStore() {
    _classCallCheck(this, GlobalsStore);

    this.allowedGlobalNames = void 0;
    this.initialGlobals = void 0;
    this.globals = {};
  }

  _createClass(GlobalsStore, [{
    key: "set",
    value: function set(_ref) {
      var _ref$globals = _ref.globals,
          globals = _ref$globals === void 0 ? {} : _ref$globals,
          _ref$globalTypes = _ref.globalTypes,
          globalTypes = _ref$globalTypes === void 0 ? {} : _ref$globalTypes;
      var delta = this.initialGlobals && (0, _args.deepDiff)(this.initialGlobals, this.globals);
      this.allowedGlobalNames = new Set([].concat(_toConsumableArray(Object.keys(globals)), _toConsumableArray(Object.keys(globalTypes))));
      var defaultGlobals = (0, _getValuesFromArgTypes.getValuesFromArgTypes)(globalTypes);
      this.initialGlobals = Object.assign({}, defaultGlobals, globals);
      this.globals = this.initialGlobals;

      if (delta && delta !== _args.DEEPLY_EQUAL) {
        this.updateFromPersisted(delta);
      }
    }
  }, {
    key: "filterAllowedGlobals",
    value: function filterAllowedGlobals(globals) {
      var _this = this;

      return Object.entries(globals).reduce(function (acc, _ref2) {
        var _ref3 = _slicedToArray(_ref2, 2),
            key = _ref3[0],
            value = _ref3[1];

        if (_this.allowedGlobalNames.has(key)) acc[key] = value;
        return acc;
      }, {});
    }
  }, {
    key: "updateFromPersisted",
    value: function updateFromPersisted(persisted) {
      var allowedUrlGlobals = this.filterAllowedGlobals(persisted); // Note that unlike args, we do not have the same type information for globals to allow us
      // to type check them here, so we just set them naively

      this.globals = Object.assign({}, this.globals, allowedUrlGlobals);
    }
  }, {
    key: "get",
    value: function get() {
      return this.globals;
    }
  }, {
    key: "update",
    value: function update(newGlobals) {
      var _this2 = this;

      Object.keys(newGlobals).forEach(function (key) {
        if (!_this2.allowedGlobalNames.has(key)) {
          setUndeclaredWarning();
        }
      });
      this.globals = Object.assign({}, this.globals, newGlobals);
    }
  }]);

  return GlobalsStore;
}();

exports.GlobalsStore = GlobalsStore;