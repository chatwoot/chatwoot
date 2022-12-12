Object.defineProperty(exports, "__esModule", { value: true });
var utils_1 = require("@sentry/utils");
/** Noop transport */
var NoopTransport = /** @class */ (function () {
    function NoopTransport() {
    }
    /**
     * @inheritDoc
     */
    NoopTransport.prototype.sendEvent = function (_) {
        return utils_1.resolvedSyncPromise({
            reason: 'NoopTransport: Event has been skipped because no Dsn is configured.',
            status: 'skipped',
        });
    };
    /**
     * @inheritDoc
     */
    NoopTransport.prototype.close = function (_) {
        return utils_1.resolvedSyncPromise(true);
    };
    return NoopTransport;
}());
exports.NoopTransport = NoopTransport;
//# sourceMappingURL=noop.js.map