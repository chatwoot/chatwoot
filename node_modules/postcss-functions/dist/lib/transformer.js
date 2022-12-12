'use strict';

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _postcssValueParser = require('postcss-value-parser');

var _postcssValueParser2 = _interopRequireDefault(_postcssValueParser);

var _helpers = require('./helpers');

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = function (functions) {

    function transformValue(node, prop) {
        var promises = [];

        var values = (0, _postcssValueParser2.default)(node[prop]).walk(function (part) {
            promises.push(transform(part));
        });

        if ((0, _helpers.hasPromises)(promises)) promises = Promise.all(promises);

        return (0, _helpers.then)(promises, function () {
            node[prop] = values.toString();
        });
    }

    function transform(node) {
        if (node.type !== 'function' || !functions.hasOwnProperty(node.value)) return node;

        var func = functions[node.value];
        return (0, _helpers.then)(extractArguments(node.nodes), function (args) {
            var invocation = func.apply(func, args);

            return (0, _helpers.then)(invocation, function (val) {
                node.type = 'word';
                node.value = val;
                return node;
            });
        });
    }

    function extractArguments(nodes) {
        nodes = nodes.map(function (node) {
            return transform(node);
        });

        if ((0, _helpers.hasPromises)(nodes)) nodes = Promise.all(nodes);

        return (0, _helpers.then)(nodes, function (values) {
            var args = [];
            var last = values.reduce(function (prev, node) {
                if (node.type === 'div' && node.value === ',') {
                    args.push(prev);
                    return '';
                }
                return prev + _postcssValueParser2.default.stringify(node);
            }, '');

            if (last) args.push(last);

            return args;
        });
    }

    return function (node) {
        switch (node.type) {
            case 'decl':
                return transformValue(node, 'value');
            case 'atrule':
                return transformValue(node, 'params');
            case 'rule':
                return transformValue(node, 'selector');
        }
    };
};

module.exports = exports['default'];