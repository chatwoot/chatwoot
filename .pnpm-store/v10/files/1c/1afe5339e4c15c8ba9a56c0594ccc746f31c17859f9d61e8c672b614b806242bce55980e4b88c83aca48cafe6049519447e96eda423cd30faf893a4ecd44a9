"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SessionPropsManager = void 0;
/* Store some session-level attribution-related properties in the persistence layer
 *
 * These have the same lifespan as a session_id, meaning that if the session_id changes, these properties will be reset.
 *
 * We only store the entry URL and referrer, and derive many props (such as utm tags) from those.
 *
 * Given that the cookie is limited to 4K bytes, we don't want to store too much data, so we chose not to store device
 * properties (such as browser, OS, etc) here, as usually getting the current value of those from event properties is
 * sufficient.
 */
var event_utils_1 = require("./utils/event-utils");
var constants_1 = require("./constants");
var utils_1 = require("./utils");
var core_1 = require("@posthog/core");
var generateSessionSourceParams = function (posthog) {
    return (0, event_utils_1.getPersonInfo)(posthog === null || posthog === void 0 ? void 0 : posthog.config.mask_personal_data_properties, posthog === null || posthog === void 0 ? void 0 : posthog.config.custom_personal_data_properties);
};
var SessionPropsManager = /** @class */ (function () {
    function SessionPropsManager(instance, sessionIdManager, persistence, sessionSourceParamGenerator) {
        var _this = this;
        this._onSessionIdCallback = function (sessionId) {
            var _a;
            var stored = _this._getStored();
            if (stored && stored.sessionId === sessionId) {
                return;
            }
            var newProps = {
                sessionId: sessionId,
                props: _this._sessionSourceParamGenerator(_this._instance),
            };
            _this._persistence.register((_a = {}, _a[constants_1.CLIENT_SESSION_PROPS] = newProps, _a));
        };
        this._instance = instance;
        this._sessionIdManager = sessionIdManager;
        this._persistence = persistence;
        this._sessionSourceParamGenerator = sessionSourceParamGenerator || generateSessionSourceParams;
        this._sessionIdManager.onSessionId(this._onSessionIdCallback);
    }
    SessionPropsManager.prototype._getStored = function () {
        return this._persistence.props[constants_1.CLIENT_SESSION_PROPS];
    };
    SessionPropsManager.prototype.getSetOnceProps = function () {
        var _a;
        var p = (_a = this._getStored()) === null || _a === void 0 ? void 0 : _a.props;
        if (!p) {
            return {};
        }
        if ('r' in p) {
            return (0, event_utils_1.getPersonPropsFromInfo)(p);
        }
        else {
            return {
                $referring_domain: p.referringDomain,
                $pathname: p.initialPathName,
                utm_source: p.utm_source,
                utm_campaign: p.utm_campaign,
                utm_medium: p.utm_medium,
                utm_content: p.utm_content,
                utm_term: p.utm_term,
            };
        }
    };
    SessionPropsManager.prototype.getSessionProps = function () {
        // it's the same props, but don't include null for unset properties, and add a prefix
        var p = {};
        (0, utils_1.each)((0, utils_1.stripEmptyProperties)(this.getSetOnceProps()), function (v, k) {
            if (k === '$current_url') {
                // $session_entry_current_url would be a weird name, call it $session_entry_url instead
                k = 'url';
            }
            p["$session_entry_".concat((0, core_1.stripLeadingDollar)(k))] = v;
        });
        return p;
    };
    return SessionPropsManager;
}());
exports.SessionPropsManager = SessionPropsManager;
//# sourceMappingURL=session-props.js.map