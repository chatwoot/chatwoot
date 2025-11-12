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
exports.EventTriggerMatching = exports.LinkedFlagMatching = exports.URLTriggerMatching = exports.PendingTriggerMatching = exports.AndTriggerMatching = exports.OrTriggerMatching = exports.TRIGGER_DISABLED = exports.TRIGGER_PENDING = exports.TRIGGER_ACTIVATED = exports.PAUSED = exports.BUFFERING = exports.ACTIVE = exports.SAMPLED = exports.DISABLED = void 0;
exports.nullMatchSessionRecordingStatus = nullMatchSessionRecordingStatus;
exports.anyMatchSessionRecordingStatus = anyMatchSessionRecordingStatus;
exports.allMatchSessionRecordingStatus = allMatchSessionRecordingStatus;
var constants_1 = require("../../constants");
var core_1 = require("@posthog/core");
var globals_1 = require("../../utils/globals");
exports.DISABLED = 'disabled';
exports.SAMPLED = 'sampled';
exports.ACTIVE = 'active';
exports.BUFFERING = 'buffering';
exports.PAUSED = 'paused';
var TRIGGER = 'trigger';
exports.TRIGGER_ACTIVATED = TRIGGER + '_activated';
exports.TRIGGER_PENDING = TRIGGER + '_pending';
exports.TRIGGER_DISABLED = TRIGGER + '_' + exports.DISABLED;
/*
triggers can have one of three statuses:
 * - trigger_activated: the trigger met conditions to start recording
 * - trigger_pending: the trigger is present, but the conditions are not yet met
 * - trigger_disabled: the trigger is not present
 */
// eslint-disable-next-line @typescript-eslint/no-unused-vars
var triggerStatuses = [exports.TRIGGER_ACTIVATED, exports.TRIGGER_PENDING, exports.TRIGGER_DISABLED];
/**
 * Session recording starts in buffering mode while waiting for "flags response".
 * Once the response is received, it might be disabled, active or sampled.
 * When "sampled" that means a sample rate is set, and the last time the session ID rotated
 * the sample rate determined this session should be sent to the server.
 */
// eslint-disable-next-line @typescript-eslint/no-unused-vars
var sessionRecordingStatuses = [exports.DISABLED, exports.SAMPLED, exports.ACTIVE, exports.BUFFERING, exports.PAUSED];
function sessionRecordingUrlTriggerMatches(url, triggers) {
    return triggers.some(function (trigger) {
        switch (trigger.matching) {
            case 'regex':
                return new RegExp(trigger.url).test(url);
            default:
                return false;
        }
    });
}
var OrTriggerMatching = /** @class */ (function () {
    function OrTriggerMatching(_matchers) {
        this._matchers = _matchers;
    }
    OrTriggerMatching.prototype.triggerStatus = function (sessionId) {
        var statuses = this._matchers.map(function (m) { return m.triggerStatus(sessionId); });
        if (statuses.includes(exports.TRIGGER_ACTIVATED)) {
            return exports.TRIGGER_ACTIVATED;
        }
        if (statuses.includes(exports.TRIGGER_PENDING)) {
            return exports.TRIGGER_PENDING;
        }
        return exports.TRIGGER_DISABLED;
    };
    OrTriggerMatching.prototype.stop = function () {
        this._matchers.forEach(function (m) { return m.stop(); });
    };
    return OrTriggerMatching;
}());
exports.OrTriggerMatching = OrTriggerMatching;
var AndTriggerMatching = /** @class */ (function () {
    function AndTriggerMatching(_matchers) {
        this._matchers = _matchers;
    }
    AndTriggerMatching.prototype.triggerStatus = function (sessionId) {
        var e_1, _a;
        var statuses = new Set();
        try {
            for (var _b = __values(this._matchers), _c = _b.next(); !_c.done; _c = _b.next()) {
                var matcher = _c.value;
                statuses.add(matcher.triggerStatus(sessionId));
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (_c && !_c.done && (_a = _b.return)) _a.call(_b);
            }
            finally { if (e_1) throw e_1.error; }
        }
        // trigger_disabled means no config
        statuses.delete(exports.TRIGGER_DISABLED);
        switch (statuses.size) {
            case 0:
                return exports.TRIGGER_DISABLED;
            case 1:
                return Array.from(statuses)[0];
            default:
                return exports.TRIGGER_PENDING;
        }
    };
    AndTriggerMatching.prototype.stop = function () {
        this._matchers.forEach(function (m) { return m.stop(); });
    };
    return AndTriggerMatching;
}());
exports.AndTriggerMatching = AndTriggerMatching;
var PendingTriggerMatching = /** @class */ (function () {
    function PendingTriggerMatching() {
    }
    PendingTriggerMatching.prototype.triggerStatus = function () {
        return exports.TRIGGER_PENDING;
    };
    PendingTriggerMatching.prototype.stop = function () {
        // no-op
    };
    return PendingTriggerMatching;
}());
exports.PendingTriggerMatching = PendingTriggerMatching;
var URLTriggerMatching = /** @class */ (function () {
    function URLTriggerMatching(_instance) {
        this._instance = _instance;
        this._urlTriggers = [];
        this._urlBlocklist = [];
        this.urlBlocked = false;
    }
    URLTriggerMatching.prototype.onRemoteConfig = function (response) {
        var _a, _b;
        this._urlTriggers = ((_a = response.sessionRecording) === null || _a === void 0 ? void 0 : _a.urlTriggers) || [];
        this._urlBlocklist = ((_b = response.sessionRecording) === null || _b === void 0 ? void 0 : _b.urlBlocklist) || [];
    };
    URLTriggerMatching.prototype._urlTriggerStatus = function (sessionId) {
        var _a;
        if (this._urlTriggers.length === 0) {
            return exports.TRIGGER_DISABLED;
        }
        var currentTriggerSession = (_a = this._instance) === null || _a === void 0 ? void 0 : _a.get_property(constants_1.SESSION_RECORDING_URL_TRIGGER_ACTIVATED_SESSION);
        return currentTriggerSession === sessionId ? exports.TRIGGER_ACTIVATED : exports.TRIGGER_PENDING;
    };
    URLTriggerMatching.prototype.triggerStatus = function (sessionId) {
        var urlTriggerStatus = this._urlTriggerStatus(sessionId);
        var eitherIsActivated = urlTriggerStatus === exports.TRIGGER_ACTIVATED;
        var eitherIsPending = urlTriggerStatus === exports.TRIGGER_PENDING;
        var result = eitherIsActivated ? exports.TRIGGER_ACTIVATED : eitherIsPending ? exports.TRIGGER_PENDING : exports.TRIGGER_DISABLED;
        this._instance.register_for_session({
            $sdk_debug_replay_url_trigger_status: result,
        });
        return result;
    };
    URLTriggerMatching.prototype.checkUrlTriggerConditions = function (onPause, onResume, onActivate) {
        if (typeof globals_1.window === 'undefined' || !globals_1.window.location.href) {
            return;
        }
        var url = globals_1.window.location.href;
        var wasBlocked = this.urlBlocked;
        var isNowBlocked = sessionRecordingUrlTriggerMatches(url, this._urlBlocklist);
        if (wasBlocked && isNowBlocked) {
            // if the url is blocked and was already blocked, do nothing
            return;
        }
        else if (isNowBlocked && !wasBlocked) {
            onPause();
        }
        else if (!isNowBlocked && wasBlocked) {
            onResume();
        }
        if (sessionRecordingUrlTriggerMatches(url, this._urlTriggers)) {
            onActivate('url');
        }
    };
    URLTriggerMatching.prototype.stop = function () {
        // no-op
    };
    return URLTriggerMatching;
}());
exports.URLTriggerMatching = URLTriggerMatching;
var LinkedFlagMatching = /** @class */ (function () {
    function LinkedFlagMatching(_instance) {
        this._instance = _instance;
        this.linkedFlag = null;
        this.linkedFlagSeen = false;
        this._flaglistenerCleanup = function () { };
    }
    LinkedFlagMatching.prototype.triggerStatus = function () {
        var result = exports.TRIGGER_PENDING;
        if ((0, core_1.isNullish)(this.linkedFlag)) {
            result = exports.TRIGGER_DISABLED;
        }
        if (this.linkedFlagSeen) {
            result = exports.TRIGGER_ACTIVATED;
        }
        this._instance.register_for_session({
            $sdk_debug_replay_linked_flag_trigger_status: result,
        });
        return result;
    };
    LinkedFlagMatching.prototype.onRemoteConfig = function (response, onStarted) {
        var _this = this;
        var _a;
        this.linkedFlag = ((_a = response.sessionRecording) === null || _a === void 0 ? void 0 : _a.linkedFlag) || null;
        if (!(0, core_1.isNullish)(this.linkedFlag) && !this.linkedFlagSeen) {
            var linkedFlag_1 = (0, core_1.isString)(this.linkedFlag) ? this.linkedFlag : this.linkedFlag.flag;
            var linkedVariant_1 = (0, core_1.isString)(this.linkedFlag) ? null : this.linkedFlag.variant;
            this._flaglistenerCleanup = this._instance.onFeatureFlags(function (_flags, variants) {
                var flagIsPresent = (0, core_1.isObject)(variants) && linkedFlag_1 in variants;
                var linkedFlagMatches = false;
                if (flagIsPresent) {
                    var variantForFlagKey = variants[linkedFlag_1];
                    if ((0, core_1.isBoolean)(variantForFlagKey)) {
                        linkedFlagMatches = variantForFlagKey === true;
                    }
                    else if (linkedVariant_1) {
                        linkedFlagMatches = variantForFlagKey === linkedVariant_1;
                    }
                    else {
                        // then this is a variant flag and we want to match any string
                        linkedFlagMatches = !!variantForFlagKey;
                    }
                }
                _this.linkedFlagSeen = linkedFlagMatches;
                if (linkedFlagMatches) {
                    onStarted(linkedFlag_1, linkedVariant_1);
                }
            });
        }
    };
    LinkedFlagMatching.prototype.stop = function () {
        this._flaglistenerCleanup();
    };
    return LinkedFlagMatching;
}());
exports.LinkedFlagMatching = LinkedFlagMatching;
var EventTriggerMatching = /** @class */ (function () {
    function EventTriggerMatching(_instance) {
        this._instance = _instance;
        this._eventTriggers = [];
    }
    EventTriggerMatching.prototype.onRemoteConfig = function (response) {
        var _a;
        this._eventTriggers = ((_a = response.sessionRecording) === null || _a === void 0 ? void 0 : _a.eventTriggers) || [];
    };
    EventTriggerMatching.prototype._eventTriggerStatus = function (sessionId) {
        var _a;
        if (this._eventTriggers.length === 0) {
            return exports.TRIGGER_DISABLED;
        }
        var currentTriggerSession = (_a = this._instance) === null || _a === void 0 ? void 0 : _a.get_property(constants_1.SESSION_RECORDING_EVENT_TRIGGER_ACTIVATED_SESSION);
        return currentTriggerSession === sessionId ? exports.TRIGGER_ACTIVATED : exports.TRIGGER_PENDING;
    };
    EventTriggerMatching.prototype.triggerStatus = function (sessionId) {
        var eventTriggerStatus = this._eventTriggerStatus(sessionId);
        var result = eventTriggerStatus === exports.TRIGGER_ACTIVATED
            ? exports.TRIGGER_ACTIVATED
            : eventTriggerStatus === exports.TRIGGER_PENDING
                ? exports.TRIGGER_PENDING
                : exports.TRIGGER_DISABLED;
        this._instance.register_for_session({
            $sdk_debug_replay_event_trigger_status: result,
        });
        return result;
    };
    EventTriggerMatching.prototype.stop = function () {
        // no-op
    };
    return EventTriggerMatching;
}());
exports.EventTriggerMatching = EventTriggerMatching;
// we need a no-op matcher before we can lazy-load the other matches, since all matchers wait on remote config anyway
function nullMatchSessionRecordingStatus(triggersStatus) {
    if (!triggersStatus.isRecordingEnabled) {
        return exports.DISABLED;
    }
    return exports.BUFFERING;
}
function anyMatchSessionRecordingStatus(triggersStatus) {
    if (!triggersStatus.receivedFlags) {
        return exports.BUFFERING;
    }
    if (!triggersStatus.isRecordingEnabled) {
        return exports.DISABLED;
    }
    if (triggersStatus.urlTriggerMatching.urlBlocked) {
        return exports.PAUSED;
    }
    var sampledActive = triggersStatus.isSampled === true;
    var triggerMatches = new OrTriggerMatching([
        triggersStatus.eventTriggerMatching,
        triggersStatus.urlTriggerMatching,
        triggersStatus.linkedFlagMatching,
    ]).triggerStatus(triggersStatus.sessionId);
    if (sampledActive) {
        return exports.SAMPLED;
    }
    if (triggerMatches === exports.TRIGGER_ACTIVATED) {
        return exports.ACTIVE;
    }
    if (triggerMatches === exports.TRIGGER_PENDING) {
        // even if sampled active is false, we should still be buffering
        // since a pending trigger could override it
        return exports.BUFFERING;
    }
    // if sampling is set and the session is already decided to not be sampled
    // then we should never be active
    if (triggersStatus.isSampled === false) {
        return exports.DISABLED;
    }
    return exports.ACTIVE;
}
function allMatchSessionRecordingStatus(triggersStatus) {
    if (!triggersStatus.receivedFlags) {
        return exports.BUFFERING;
    }
    if (!triggersStatus.isRecordingEnabled) {
        return exports.DISABLED;
    }
    if (triggersStatus.urlTriggerMatching.urlBlocked) {
        return exports.PAUSED;
    }
    var andTriggerMatch = new AndTriggerMatching([
        triggersStatus.eventTriggerMatching,
        triggersStatus.urlTriggerMatching,
        triggersStatus.linkedFlagMatching,
    ]);
    var currentTriggerStatus = andTriggerMatch.triggerStatus(triggersStatus.sessionId);
    var hasTriggersConfigured = currentTriggerStatus !== exports.TRIGGER_DISABLED;
    var hasSamplingConfigured = (0, core_1.isBoolean)(triggersStatus.isSampled);
    if (hasTriggersConfigured && currentTriggerStatus === exports.TRIGGER_PENDING) {
        return exports.BUFFERING;
    }
    if (hasTriggersConfigured && currentTriggerStatus === exports.TRIGGER_DISABLED) {
        return exports.DISABLED;
    }
    // sampling can't ever cause buffering, it's always determined right away or not configured
    if (hasSamplingConfigured && !triggersStatus.isSampled) {
        return exports.DISABLED;
    }
    // If sampling is configured and set to true, return sampled
    if (triggersStatus.isSampled === true) {
        return exports.SAMPLED;
    }
    return exports.ACTIVE;
}
//# sourceMappingURL=triggerMatching.js.map