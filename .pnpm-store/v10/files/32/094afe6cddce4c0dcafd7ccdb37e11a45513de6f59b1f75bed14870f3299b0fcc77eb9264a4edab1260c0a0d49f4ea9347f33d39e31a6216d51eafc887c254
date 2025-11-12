"use strict";
var __values = (this && this.__values) || function(o) {
    var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
    if (m) return m.call(o);
    if (o && typeof o.length === "number") return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
    throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SimpleEventEmitter = void 0;
var SimpleEventEmitter = /** @class */ (function () {
    function SimpleEventEmitter() {
        this._events = {};
        this._events = {};
    }
    SimpleEventEmitter.prototype.on = function (event, listener) {
        var _this = this;
        if (!this._events[event]) {
            this._events[event] = [];
        }
        this._events[event].push(listener);
        return function () {
            _this._events[event] = _this._events[event].filter(function (x) { return x !== listener; });
        };
    };
    SimpleEventEmitter.prototype.emit = function (event, payload) {
        var e_1, _a, e_2, _b;
        try {
            for (var _c = __values(this._events[event] || []), _d = _c.next(); !_d.done; _d = _c.next()) {
                var listener = _d.value;
                listener(payload);
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (_d && !_d.done && (_a = _c.return)) _a.call(_c);
            }
            finally { if (e_1) throw e_1.error; }
        }
        try {
            for (var _e = __values(this._events['*'] || []), _f = _e.next(); !_f.done; _f = _e.next()) {
                var listener = _f.value;
                listener(event, payload);
            }
        }
        catch (e_2_1) { e_2 = { error: e_2_1 }; }
        finally {
            try {
                if (_f && !_f.done && (_b = _e.return)) _b.call(_e);
            }
            finally { if (e_2) throw e_2.error; }
        }
    };
    return SimpleEventEmitter;
}());
exports.SimpleEventEmitter = SimpleEventEmitter;
//# sourceMappingURL=simple-event-emitter.js.map