import { resolvedSyncPromise } from '@sentry/utils';
/** Noop transport */
var NoopTransport = /** @class */ (function () {
    function NoopTransport() {
    }
    /**
     * @inheritDoc
     */
    NoopTransport.prototype.sendEvent = function (_) {
        return resolvedSyncPromise({
            reason: 'NoopTransport: Event has been skipped because no Dsn is configured.',
            status: 'skipped',
        });
    };
    /**
     * @inheritDoc
     */
    NoopTransport.prototype.close = function (_) {
        return resolvedSyncPromise(true);
    };
    return NoopTransport;
}());
export { NoopTransport };
//# sourceMappingURL=noop.js.map