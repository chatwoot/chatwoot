'use strict';

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = consoleFunc;

var _wrapAsync = require('./wrapAsync');

var _wrapAsync2 = _interopRequireDefault(_wrapAsync);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function consoleFunc(name) {
    return (fn, ...args) => (0, _wrapAsync2.default)(fn)(...args, (err, ...resultArgs) => {
        if (typeof console === 'object') {
            if (err) {
                if (console.error) {
                    console.error(err);
                }
            } else if (console[name]) {
                resultArgs.forEach(x => console[name](x));
            }
        }
    });
}
module.exports = exports['default'];