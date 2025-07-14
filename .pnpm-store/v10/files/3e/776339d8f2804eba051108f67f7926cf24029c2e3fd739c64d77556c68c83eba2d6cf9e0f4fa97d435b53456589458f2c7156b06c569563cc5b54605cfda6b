"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EventFactory = void 0;
var tslib_1 = require("tslib");
var uuid_1 = require("@lukeed/uuid");
var dset_1 = require("dset");
var spark_md5_1 = tslib_1.__importDefault(require("spark-md5"));
tslib_1.__exportStar(require("./interfaces"), exports);
var EventFactory = /** @class */ (function () {
    function EventFactory(user) {
        this.user = user;
    }
    EventFactory.prototype.track = function (event, properties, options, globalIntegrations) {
        return this.normalize(tslib_1.__assign(tslib_1.__assign({}, this.baseEvent()), { event: event, type: 'track', properties: properties, options: tslib_1.__assign({}, options), integrations: tslib_1.__assign({}, globalIntegrations) }));
    };
    EventFactory.prototype.page = function (category, page, properties, options, globalIntegrations) {
        var _a;
        var event = {
            type: 'page',
            properties: tslib_1.__assign({}, properties),
            options: tslib_1.__assign({}, options),
            integrations: tslib_1.__assign({}, globalIntegrations),
        };
        if (category !== null) {
            event.category = category;
            event.properties = (_a = event.properties) !== null && _a !== void 0 ? _a : {};
            event.properties.category = category;
        }
        if (page !== null) {
            event.name = page;
        }
        return this.normalize(tslib_1.__assign(tslib_1.__assign({}, this.baseEvent()), event));
    };
    EventFactory.prototype.screen = function (category, screen, properties, options, globalIntegrations) {
        var event = {
            type: 'screen',
            properties: tslib_1.__assign({}, properties),
            options: tslib_1.__assign({}, options),
            integrations: tslib_1.__assign({}, globalIntegrations),
        };
        if (category !== null) {
            event.category = category;
        }
        if (screen !== null) {
            event.name = screen;
        }
        return this.normalize(tslib_1.__assign(tslib_1.__assign({}, this.baseEvent()), event));
    };
    EventFactory.prototype.identify = function (userId, traits, options, globalIntegrations) {
        return this.normalize(tslib_1.__assign(tslib_1.__assign({}, this.baseEvent()), { type: 'identify', userId: userId, traits: traits, options: tslib_1.__assign({}, options), integrations: tslib_1.__assign({}, globalIntegrations) }));
    };
    EventFactory.prototype.group = function (groupId, traits, options, globalIntegrations) {
        return this.normalize(tslib_1.__assign(tslib_1.__assign({}, this.baseEvent()), { type: 'group', traits: traits, options: tslib_1.__assign({}, options), integrations: tslib_1.__assign({}, globalIntegrations), groupId: groupId }));
    };
    EventFactory.prototype.alias = function (to, from, options, globalIntegrations) {
        var base = {
            userId: to,
            type: 'alias',
            options: tslib_1.__assign({}, options),
            integrations: tslib_1.__assign({}, globalIntegrations),
        };
        if (from !== null) {
            base.previousId = from;
        }
        if (to === undefined) {
            return this.normalize(tslib_1.__assign(tslib_1.__assign({}, base), this.baseEvent()));
        }
        return this.normalize(tslib_1.__assign(tslib_1.__assign({}, this.baseEvent()), base));
    };
    EventFactory.prototype.baseEvent = function () {
        var base = {
            integrations: {},
            options: {},
        };
        var user = this.user;
        if (user.id()) {
            base.userId = user.id();
        }
        if (user.anonymousId()) {
            base.anonymousId = user.anonymousId();
        }
        return base;
    };
    /**
     * Builds the context part of an event based on "foreign" keys that
     * are provided in the `Options` parameter for an Event
     */
    EventFactory.prototype.context = function (event) {
        var _a, _b, _c;
        var optionsKeys = ['integrations', 'anonymousId', 'timestamp', 'userId'];
        var options = (_a = event.options) !== null && _a !== void 0 ? _a : {};
        delete options['integrations'];
        var providedOptionsKeys = Object.keys(options);
        var context = (_c = (_b = event.options) === null || _b === void 0 ? void 0 : _b.context) !== null && _c !== void 0 ? _c : {};
        var overrides = {};
        providedOptionsKeys.forEach(function (key) {
            if (key === 'context') {
                return;
            }
            if (optionsKeys.includes(key)) {
                (0, dset_1.dset)(overrides, key, options[key]);
            }
            else {
                (0, dset_1.dset)(context, key, options[key]);
            }
        });
        return [context, overrides];
    };
    EventFactory.prototype.normalize = function (event) {
        var _a, _b, _c;
        // set anonymousId globally if we encounter an override
        //segment.com/docs/connections/sources/catalog/libraries/website/javascript/identity/#override-the-anonymous-id-using-the-options-object
        ((_a = event.options) === null || _a === void 0 ? void 0 : _a.anonymousId) &&
            this.user.anonymousId(event.options.anonymousId);
        var integrationBooleans = Object.keys((_b = event.integrations) !== null && _b !== void 0 ? _b : {}).reduce(function (integrationNames, name) {
            var _a;
            var _b;
            return tslib_1.__assign(tslib_1.__assign({}, integrationNames), (_a = {}, _a[name] = Boolean((_b = event.integrations) === null || _b === void 0 ? void 0 : _b[name]), _a));
        }, {});
        // This is pretty trippy, but here's what's going on:
        // - a) We don't pass initial integration options as part of the event, only if they're true or false
        // - b) We do accept per integration overrides (like integrations.Amplitude.sessionId) at the event level
        // Hence the need to convert base integration options to booleans, but maintain per event integration overrides
        var allIntegrations = tslib_1.__assign(tslib_1.__assign({}, integrationBooleans), (_c = event.options) === null || _c === void 0 ? void 0 : _c.integrations);
        var _d = this.context(event), context = _d[0], overrides = _d[1];
        var options = event.options, rest = tslib_1.__rest(event, ["options"]);
        var body = tslib_1.__assign(tslib_1.__assign(tslib_1.__assign({ timestamp: new Date() }, rest), { context: context, integrations: allIntegrations }), overrides);
        var messageId = 'ajs-next-' + spark_md5_1.default.hash(JSON.stringify(body) + (0, uuid_1.v4)());
        var evt = tslib_1.__assign(tslib_1.__assign({}, body), { messageId: messageId });
        return evt;
    };
    return EventFactory;
}());
exports.EventFactory = EventFactory;
//# sourceMappingURL=index.js.map