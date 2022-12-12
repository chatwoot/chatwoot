'use strict';

Object.defineProperty(exports, "__esModule", {
	value: true
});

var _path = require('path');

var _path2 = _interopRequireDefault(_path);

var _glob = require('glob');

var _glob2 = _interopRequireDefault(_glob);

var _postcss = require('postcss');

var _transformer = require('./lib/transformer');

var _transformer2 = _interopRequireDefault(_transformer);

var _helpers = require('./lib/helpers');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = (0, _postcss.plugin)('postcss-functions', function () {
	var opts = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

	var functions = opts.functions || {};
	var globs = opts.glob || [];

	if (!Array.isArray(globs)) globs = [globs];

	globs.forEach(function (pattern) {
		_glob2.default.sync(pattern).forEach(function (file) {
			var name = _path2.default.basename(file, _path2.default.extname(file));
			functions[name] = require(file);
		});
	});

	var transform = (0, _transformer2.default)(functions);

	return function (css) {
		var promises = [];
		css.walk(function (node) {
			promises.push(transform(node));
		});

		if ((0, _helpers.hasPromises)(promises)) return Promise.all(promises);
	};
});
module.exports = exports['default'];