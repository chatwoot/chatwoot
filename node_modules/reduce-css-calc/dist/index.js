'use strict';

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _postcssValueParser = require('postcss-value-parser');

var _postcssValueParser2 = _interopRequireDefault(_postcssValueParser);

var _parser = require('./parser');

var _reducer = require('./lib/reducer');

var _reducer2 = _interopRequireDefault(_reducer);

var _stringifier = require('./lib/stringifier');

var _stringifier2 = _interopRequireDefault(_stringifier);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// eslint-disable-line
var MATCH_CALC = /((?:\-[a-z]+\-)?calc)/;

exports.default = function (value) {
  var precision = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : 5;

  return (0, _postcssValueParser2.default)(value).walk(function (node) {
    // skip anything which isn't a calc() function
    if (node.type !== 'function' || !MATCH_CALC.test(node.value)) return;

    // stringify calc expression and produce an AST
    var contents = _postcssValueParser2.default.stringify(node.nodes);

    // skip constant() and env()
    if (contents.indexOf('constant') >= 0 || contents.indexOf('env') >= 0) return;

    var ast = _parser.parser.parse(contents);

    // reduce AST to its simplest form, that is, either to a single value
    // or a simplified calc expression
    var reducedAst = (0, _reducer2.default)(ast, precision);

    // stringify AST and write it back
    node.type = 'word';
    node.value = (0, _stringifier2.default)(node.value, reducedAst, precision);
  }, true).toString();
};

module.exports = exports['default'];