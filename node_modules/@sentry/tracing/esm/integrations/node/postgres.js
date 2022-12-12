import { fill, isThenable, loadModule, logger } from '@sentry/utils';
import { IS_DEBUG_BUILD } from '../../flags';
/** Tracing integration for node-postgres package */
var Postgres = /** @class */ (function () {
    function Postgres(options) {
        if (options === void 0) { options = {}; }
        /**
         * @inheritDoc
         */
        this.name = Postgres.id;
        this._usePgNative = !!options.usePgNative;
    }
    /**
     * @inheritDoc
     */
    Postgres.prototype.setupOnce = function (_, getCurrentHub) {
        var _a;
        var pkg = loadModule('pg');
        if (!pkg) {
            IS_DEBUG_BUILD && logger.error('Postgres Integration was unable to require `pg` package.');
            return;
        }
        if (this._usePgNative && !((_a = pkg.native) === null || _a === void 0 ? void 0 : _a.Client)) {
            IS_DEBUG_BUILD && logger.error("Postgres Integration was unable to access 'pg-native' bindings.");
            return;
        }
        var Client = (this._usePgNative ? pkg.native : pkg).Client;
        /**
         * function (query, callback) => void
         * function (query, params, callback) => void
         * function (query) => Promise
         * function (query, params) => Promise
         * function (pg.Cursor) => pg.Cursor
         */
        fill(Client.prototype, 'query', function (orig) {
            return function (config, values, callback) {
                var _a, _b, _c;
                var scope = getCurrentHub().getScope();
                var parentSpan = (_a = scope) === null || _a === void 0 ? void 0 : _a.getSpan();
                var span = (_b = parentSpan) === null || _b === void 0 ? void 0 : _b.startChild({
                    description: typeof config === 'string' ? config : config.text,
                    op: 'db',
                });
                if (typeof callback === 'function') {
                    return orig.call(this, config, values, function (err, result) {
                        var _a;
                        (_a = span) === null || _a === void 0 ? void 0 : _a.finish();
                        callback(err, result);
                    });
                }
                if (typeof values === 'function') {
                    return orig.call(this, config, function (err, result) {
                        var _a;
                        (_a = span) === null || _a === void 0 ? void 0 : _a.finish();
                        values(err, result);
                    });
                }
                var rv = typeof values !== 'undefined' ? orig.call(this, config, values) : orig.call(this, config);
                if (isThenable(rv)) {
                    return rv.then(function (res) {
                        var _a;
                        (_a = span) === null || _a === void 0 ? void 0 : _a.finish();
                        return res;
                    });
                }
                (_c = span) === null || _c === void 0 ? void 0 : _c.finish();
                return rv;
            };
        });
    };
    /**
     * @inheritDoc
     */
    Postgres.id = 'Postgres';
    return Postgres;
}());
export { Postgres };
//# sourceMappingURL=postgres.js.map