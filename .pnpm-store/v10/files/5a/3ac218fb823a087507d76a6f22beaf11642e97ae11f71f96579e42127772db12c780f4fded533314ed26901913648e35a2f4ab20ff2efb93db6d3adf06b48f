import { __assign, __awaiter, __generator } from "tslib";
import { isOffline } from '../../core/connection';
import { PriorityQueue } from '../../lib/priority-queue';
import { PersistedPriorityQueue } from '../../lib/priority-queue/persisted';
import { toFacade } from '../../lib/to-facade';
import batch from './batched-dispatcher';
import standard from './fetch-dispatcher';
import { normalize } from './normalize';
import { scheduleFlush } from './schedule-flush';
function onAlias(analytics, json) {
    var _a, _b, _c, _d;
    var user = analytics.user();
    json.previousId =
        (_c = (_b = (_a = json.previousId) !== null && _a !== void 0 ? _a : json.from) !== null && _b !== void 0 ? _b : user.id()) !== null && _c !== void 0 ? _c : user.anonymousId();
    json.userId = (_d = json.userId) !== null && _d !== void 0 ? _d : json.to;
    delete json.from;
    delete json.to;
    return json;
}
export function segmentio(analytics, settings, integrations) {
    var _a, _b;
    // Attach `pagehide` before buffer is created so that inflight events are added
    // to the buffer before the buffer persists events in its own `pagehide` handler.
    window.addEventListener('pagehide', function () {
        buffer.push.apply(buffer, Array.from(inflightEvents));
        inflightEvents.clear();
    });
    var buffer = analytics.options.disableClientPersistence
        ? new PriorityQueue(analytics.queue.queue.maxAttempts, [])
        : new PersistedPriorityQueue(analytics.queue.queue.maxAttempts, "dest-june.so");
    var inflightEvents = new Set();
    var flushing = false;
    var apiHost = (_a = settings === null || settings === void 0 ? void 0 : settings.apiHost) !== null && _a !== void 0 ? _a : 'api.june.so/sdk';
    var protocol = (_b = settings === null || settings === void 0 ? void 0 : settings.protocol) !== null && _b !== void 0 ? _b : 'https';
    var remote = "".concat(protocol, "://").concat(apiHost);
    var deliveryStrategy = settings === null || settings === void 0 ? void 0 : settings.deliveryStrategy;
    var client = (deliveryStrategy === null || deliveryStrategy === void 0 ? void 0 : deliveryStrategy.strategy) === 'batching'
        ? batch(apiHost, deliveryStrategy.config)
        : standard(deliveryStrategy === null || deliveryStrategy === void 0 ? void 0 : deliveryStrategy.config);
    function send(ctx) {
        return __awaiter(this, void 0, void 0, function () {
            var path, json;
            return __generator(this, function (_a) {
                if (isOffline()) {
                    buffer.push(ctx);
                    // eslint-disable-next-line @typescript-eslint/no-use-before-define
                    scheduleFlush(flushing, buffer, segmentio, scheduleFlush);
                    return [2 /*return*/, ctx];
                }
                inflightEvents.add(ctx);
                path = ctx.event.type;
                json = toFacade(ctx.event).json();
                if (ctx.event.type === 'track') {
                    delete json.traits;
                }
                if (ctx.event.type === 'alias') {
                    json = onAlias(analytics, json);
                }
                return [2 /*return*/, client
                        .dispatch("".concat(remote, "/").concat(path), __assign(__assign({}, normalize(analytics, json, settings, integrations)), { writeKey: analytics.settings.writeKey }))
                        .then(function () { return ctx; })
                        .catch(function () {
                        buffer.pushWithBackoff(ctx);
                        // eslint-disable-next-line @typescript-eslint/no-use-before-define
                        scheduleFlush(flushing, buffer, segmentio, scheduleFlush);
                        return ctx;
                    })
                        .finally(function () {
                        inflightEvents.delete(ctx);
                    })];
            });
        });
    }
    var segmentio = {
        name: 'june.so',
        type: 'after',
        version: '0.1.0',
        isLoaded: function () { return true; },
        load: function () { return Promise.resolve(); },
        track: send,
        identify: send,
        page: send,
        alias: send,
        group: send,
    };
    // Buffer may already have items if they were previously stored in localStorage.
    // Start flushing them immediately.
    if (buffer.todo) {
        scheduleFlush(flushing, buffer, segmentio, scheduleFlush);
    }
    return segmentio;
}
//# sourceMappingURL=index.js.map