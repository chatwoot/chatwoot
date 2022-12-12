import { fill, loadModule, logger } from '@sentry/utils';
import { IS_DEBUG_BUILD } from '../../flags';
/** Tracing integration for node-mysql package */
var Mysql = /** @class */ (function () {
    function Mysql() {
        /**
         * @inheritDoc
         */
        this.name = Mysql.id;
    }
    /**
     * @inheritDoc
     */
    Mysql.prototype.setupOnce = function (_, getCurrentHub) {
        var pkg = loadModule('mysql/lib/Connection.js');
        if (!pkg) {
            IS_DEBUG_BUILD && logger.error('Mysql Integration was unable to require `mysql` package.');
            return;
        }
        // The original function will have one of these signatures:
        //    function (callback) => void
        //    function (options, callback) => void
        //    function (options, values, callback) => void
        fill(pkg, 'createQuery', function (orig) {
            return function (options, values, callback) {
                var _a, _b;
                var scope = getCurrentHub().getScope();
                var parentSpan = (_a = scope) === null || _a === void 0 ? void 0 : _a.getSpan();
                var span = (_b = parentSpan) === null || _b === void 0 ? void 0 : _b.startChild({
                    description: typeof options === 'string' ? options : options.sql,
                    op: 'db',
                });
                if (typeof callback === 'function') {
                    return orig.call(this, options, values, function (err, result, fields) {
                        var _a;
                        (_a = span) === null || _a === void 0 ? void 0 : _a.finish();
                        callback(err, result, fields);
                    });
                }
                if (typeof values === 'function') {
                    return orig.call(this, options, function (err, result, fields) {
                        var _a;
                        (_a = span) === null || _a === void 0 ? void 0 : _a.finish();
                        values(err, result, fields);
                    });
                }
                return orig.call(this, options, values, callback);
            };
        });
    };
    /**
     * @inheritDoc
     */
    Mysql.id = 'Mysql';
    return Mysql;
}());
export { Mysql };
//# sourceMappingURL=mysql.js.map