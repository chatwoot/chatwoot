import { __assign, __rest } from "tslib";
export * from './interfaces';
import { dset } from 'dset';
import { pickBy } from '../utils/pick';
import { validateEvent } from '../validation/assertions';
var EventFactory = /** @class */ (function () {
    function EventFactory(settings) {
        this.user = settings.user;
        this.createMessageId = settings.createMessageId;
    }
    EventFactory.prototype.track = function (event, properties, options, globalIntegrations) {
        return this.normalize(__assign(__assign({}, this.baseEvent()), { event: event, type: 'track', properties: properties !== null && properties !== void 0 ? properties : {}, options: __assign({}, options), integrations: __assign({}, globalIntegrations) }));
    };
    EventFactory.prototype.page = function (category, page, properties, options, globalIntegrations) {
        var _a;
        var event = {
            type: 'page',
            properties: __assign({}, properties),
            options: __assign({}, options),
            integrations: __assign({}, globalIntegrations),
        };
        if (category !== null) {
            event.category = category;
            event.properties = (_a = event.properties) !== null && _a !== void 0 ? _a : {};
            event.properties.category = category;
        }
        if (page !== null) {
            event.name = page;
        }
        return this.normalize(__assign(__assign({}, this.baseEvent()), event));
    };
    EventFactory.prototype.screen = function (category, screen, properties, options, globalIntegrations) {
        var event = {
            type: 'screen',
            properties: __assign({}, properties),
            options: __assign({}, options),
            integrations: __assign({}, globalIntegrations),
        };
        if (category !== null) {
            event.category = category;
        }
        if (screen !== null) {
            event.name = screen;
        }
        return this.normalize(__assign(__assign({}, this.baseEvent()), event));
    };
    EventFactory.prototype.identify = function (userId, traits, options, globalIntegrations) {
        return this.normalize(__assign(__assign({}, this.baseEvent()), { type: 'identify', userId: userId, traits: traits !== null && traits !== void 0 ? traits : {}, options: __assign({}, options), integrations: globalIntegrations }));
    };
    EventFactory.prototype.group = function (groupId, traits, options, globalIntegrations) {
        return this.normalize(__assign(__assign({}, this.baseEvent()), { type: 'group', traits: traits !== null && traits !== void 0 ? traits : {}, options: __assign({}, options), integrations: __assign({}, globalIntegrations), //
            groupId: groupId }));
    };
    EventFactory.prototype.alias = function (to, from, // TODO: can we make this undefined?
    options, globalIntegrations) {
        var base = {
            userId: to,
            type: 'alias',
            options: __assign({}, options),
            integrations: __assign({}, globalIntegrations),
        };
        if (from !== null) {
            base.previousId = from;
        }
        if (to === undefined) {
            return this.normalize(__assign(__assign({}, base), this.baseEvent()));
        }
        return this.normalize(__assign(__assign({}, this.baseEvent()), base));
    };
    EventFactory.prototype.baseEvent = function () {
        var base = {
            integrations: {},
            options: {},
        };
        if (!this.user)
            return base;
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
    EventFactory.prototype.context = function (options) {
        var _a;
        /**
         * If the event options are known keys from this list, we move them to the top level of the event.
         * Any other options are moved to context.
         */
        var eventOverrideKeys = [
            'userId',
            'anonymousId',
            'timestamp',
        ];
        delete options['integrations'];
        var providedOptionsKeys = Object.keys(options);
        var context = (_a = options.context) !== null && _a !== void 0 ? _a : {};
        var eventOverrides = {};
        providedOptionsKeys.forEach(function (key) {
            if (key === 'context') {
                return;
            }
            if (eventOverrideKeys.includes(key)) {
                dset(eventOverrides, key, options[key]);
            }
            else {
                dset(context, key, options[key]);
            }
        });
        return [context, eventOverrides];
    };
    EventFactory.prototype.normalize = function (event) {
        var _a, _b;
        var integrationBooleans = Object.keys((_a = event.integrations) !== null && _a !== void 0 ? _a : {}).reduce(function (integrationNames, name) {
            var _a;
            var _b;
            return __assign(__assign({}, integrationNames), (_a = {}, _a[name] = Boolean((_b = event.integrations) === null || _b === void 0 ? void 0 : _b[name]), _a));
        }, {});
        // filter out any undefined options
        event.options = pickBy(event.options || {}, function (_, value) {
            return value !== undefined;
        });
        // This is pretty trippy, but here's what's going on:
        // - a) We don't pass initial integration options as part of the event, only if they're true or false
        // - b) We do accept per integration overrides (like integrations.Amplitude.sessionId) at the event level
        // Hence the need to convert base integration options to booleans, but maintain per event integration overrides
        var allIntegrations = __assign(__assign({}, integrationBooleans), (_b = event.options) === null || _b === void 0 ? void 0 : _b.integrations);
        var _c = event.options
            ? this.context(event.options)
            : [], context = _c[0], overrides = _c[1];
        var options = event.options, rest = __rest(event, ["options"]);
        var body = __assign(__assign(__assign({ timestamp: new Date() }, rest), { integrations: allIntegrations, context: context }), overrides);
        var evt = __assign(__assign({}, body), { messageId: this.createMessageId() });
        validateEvent(evt);
        return evt;
    };
    return EventFactory;
}());
export { EventFactory };
//# sourceMappingURL=index.js.map