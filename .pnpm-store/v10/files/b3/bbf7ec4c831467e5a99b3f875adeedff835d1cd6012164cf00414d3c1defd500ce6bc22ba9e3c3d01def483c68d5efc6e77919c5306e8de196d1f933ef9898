"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PersistedPriorityQueue = void 0;
var tslib_1 = require("tslib");
var _1 = require(".");
var context_1 = require("../../core/context");
var environment_1 = require("../../core/environment");
var loc = {
    getItem: function () { },
    setItem: function () { },
    removeItem: function () { },
};
try {
    loc = (0, environment_1.isBrowser)() && window.localStorage ? window.localStorage : loc;
}
catch (err) {
    console.warn('Unable to access localStorage', err);
}
function persisted(key) {
    var items = loc.getItem(key);
    return (items ? JSON.parse(items) : []).map(function (p) { return new context_1.Context(p.event, p.id); });
}
function persistItems(key, items) {
    var existing = persisted(key);
    var all = tslib_1.__spreadArray(tslib_1.__spreadArray([], items, true), existing, true);
    var merged = all.reduce(function (acc, item) {
        var _a;
        return tslib_1.__assign(tslib_1.__assign({}, acc), (_a = {}, _a[item.id] = item, _a));
    }, {});
    loc.setItem(key, JSON.stringify(Object.values(merged)));
}
function seen(key) {
    var stored = loc.getItem(key);
    return stored ? JSON.parse(stored) : {};
}
function persistSeen(key, memory) {
    var stored = seen(key);
    loc.setItem(key, JSON.stringify(tslib_1.__assign(tslib_1.__assign({}, stored), memory)));
}
function remove(key) {
    loc.removeItem(key);
}
var now = function () { return new Date().getTime(); };
function mutex(key, onUnlock, attempt) {
    if (attempt === void 0) { attempt = 0; }
    var lockTimeout = 50;
    var lockKey = "persisted-queue:v1:".concat(key, ":lock");
    var expired = function (lock) { return new Date().getTime() > lock; };
    var rawLock = loc.getItem(lockKey);
    var lock = rawLock ? JSON.parse(rawLock) : null;
    var allowed = lock === null || expired(lock);
    if (allowed) {
        loc.setItem(lockKey, JSON.stringify(now() + lockTimeout));
        onUnlock();
        loc.removeItem(lockKey);
        return;
    }
    if (!allowed && attempt < 3) {
        setTimeout(function () {
            mutex(key, onUnlock, attempt + 1);
        }, lockTimeout);
    }
    else {
        console.error('Unable to retrieve lock');
    }
}
var PersistedPriorityQueue = /** @class */ (function (_super) {
    tslib_1.__extends(PersistedPriorityQueue, _super);
    function PersistedPriorityQueue(maxAttempts, key) {
        var _this = _super.call(this, maxAttempts, []) || this;
        var itemsKey = "persisted-queue:v1:".concat(key, ":items");
        var seenKey = "persisted-queue:v1:".concat(key, ":seen");
        var saved = [];
        var lastSeen = {};
        mutex(key, function () {
            try {
                saved = persisted(itemsKey);
                lastSeen = seen(seenKey);
                remove(itemsKey);
                remove(seenKey);
                _this.queue = tslib_1.__spreadArray(tslib_1.__spreadArray([], saved, true), _this.queue, true);
                _this.seen = tslib_1.__assign(tslib_1.__assign({}, lastSeen), _this.seen);
            }
            catch (err) {
                console.error(err);
            }
        });
        window.addEventListener('pagehide', function () {
            // we deliberately want to use the less powerful 'pagehide' API to only persist on events where the analytics instance gets destroyed, and not on tab away.
            if (_this.todo > 0) {
                var items_1 = tslib_1.__spreadArray(tslib_1.__spreadArray([], _this.queue, true), _this.future, true);
                try {
                    mutex(key, function () {
                        persistItems(itemsKey, items_1);
                        persistSeen(seenKey, _this.seen);
                    });
                }
                catch (err) {
                    console.error(err);
                }
            }
        });
        return _this;
    }
    return PersistedPriorityQueue;
}(_1.PriorityQueue));
exports.PersistedPriorityQueue = PersistedPriorityQueue;
//# sourceMappingURL=persisted.js.map