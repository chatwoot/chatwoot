"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.segmentio = void 0;
var tslib_1 = require("tslib");
var connection_1 = require("../../core/connection");
var priority_queue_1 = require("../../lib/priority-queue");
var persisted_1 = require("../../lib/priority-queue/persisted");
var to_facade_1 = require("../../lib/to-facade");
var batched_dispatcher_1 = tslib_1.__importDefault(require("./batched-dispatcher"));
var fetch_dispatcher_1 = tslib_1.__importDefault(require("./fetch-dispatcher"));
var normalize_1 = require("./normalize");
var schedule_flush_1 = require("./schedule-flush");
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
function segmentio(analytics, settings, integrations) {
    var _a, _b;
    // Attach `pagehide` before buffer is created so that inflight events are added
    // to the buffer before the buffer persists events in its own `pagehide` handler.
    window.addEventListener('pagehide', function () {
        buffer.push.apply(buffer, Array.from(inflightEvents));
        inflightEvents.clear();
    });
    var buffer = analytics.options.disableClientPersistence
        ? new priority_queue_1.PriorityQueue(analytics.queue.queue.maxAttempts, [])
        : new persisted_1.PersistedPriorityQueue(analytics.queue.queue.maxAttempts, "dest-june.so");
    var inflightEvents = new Set();
    var flushing = false;
    var apiHost = (_a = settings === null || settings === void 0 ? void 0 : settings.apiHost) !== null && _a !== void 0 ? _a : 'api.june.so/sdk';
    var protocol = (_b = settings === null || settings === void 0 ? void 0 : settings.protocol) !== null && _b !== void 0 ? _b : 'https';
    var remote = "".concat(protocol, "://").concat(apiHost);
    var deliveryStrategy = settings === null || settings === void 0 ? void 0 : settings.deliveryStrategy;
    var client = (deliveryStrategy === null || deliveryStrategy === void 0 ? void 0 : deliveryStrategy.strategy) === 'batching'
        ? (0, batched_dispatcher_1.default)(apiHost, deliveryStrategy.config)
        : (0, fetch_dispatcher_1.default)(deliveryStrategy === null || deliveryStrategy === void 0 ? void 0 : deliveryStrategy.config);
    function send(ctx) {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            var path, json;
            return tslib_1.__generator(this, function (_a) {
                if ((0, connection_1.isOffline)()) {
                    buffer.push(ctx);
                    // eslint-disable-next-line @typescript-eslint/no-use-before-define
                    (0, schedule_flush_1.scheduleFlush)(flushing, buffer, segmentio, schedule_flush_1.scheduleFlush);
                    return [2 /*return*/, ctx];
                }
                inflightEvents.add(ctx);
                path = ctx.event.type;
                json = (0, to_facade_1.toFacade)(ctx.event).json();
                if (ctx.event.type === 'track') {
                    delete json.traits;
                }
                if (ctx.event.type === 'alias') {
                    json = onAlias(analytics, json);
                }
                return [2 /*return*/, client
                        .dispatch("".concat(remote, "/").concat(path), tslib_1.__assign(tslib_1.__assign({}, (0, normalize_1.normalize)(analytics, json, settings, integrations)), { writeKey: analytics.settings.writeKey }))
                        .then(function () { return ctx; })
                        .catch(function () {
                        buffer.pushWithBackoff(ctx);
                        // eslint-disable-next-line @typescript-eslint/no-use-before-define
                        (0, schedule_flush_1.scheduleFlush)(flushing, buffer, segmentio, schedule_flush_1.scheduleFlush);
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
        (0, schedule_flush_1.scheduleFlush)(flushing, buffer, segmentio, schedule_flush_1.scheduleFlush);
    }
    return segmentio;
}
exports.segmentio = segmentio;
//# sourceMappingURL=index.js.map