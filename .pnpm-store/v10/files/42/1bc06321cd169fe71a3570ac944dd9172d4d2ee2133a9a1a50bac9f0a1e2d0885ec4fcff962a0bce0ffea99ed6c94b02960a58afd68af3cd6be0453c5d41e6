"use strict";
var __read = (this && this.__read) || function (o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SessionIdManager = exports.MAX_SESSION_IDLE_TIMEOUT_SECONDS = exports.DEFAULT_SESSION_IDLE_TIMEOUT_SECONDS = void 0;
var constants_1 = require("./constants");
var storage_1 = require("./storage");
var uuidv7_1 = require("./uuidv7");
var globals_1 = require("./utils/globals");
var logger_1 = require("./utils/logger");
var core_1 = require("@posthog/core");
var utils_1 = require("./utils");
var logger = (0, logger_1.createLogger)('[SessionId]');
exports.DEFAULT_SESSION_IDLE_TIMEOUT_SECONDS = 30 * 60; // 30 minutes
exports.MAX_SESSION_IDLE_TIMEOUT_SECONDS = 10 * 60 * 60; // 10 hours
var MIN_SESSION_IDLE_TIMEOUT_SECONDS = 60; // 1 minute
var SESSION_LENGTH_LIMIT_MILLISECONDS = 24 * 3600 * 1000; // 24 hours
var SessionIdManager = /** @class */ (function () {
    function SessionIdManager(instance, sessionIdGenerator, windowIdGenerator) {
        var _this = this;
        var _a;
        this._sessionIdChangedHandlers = [];
        this._sessionHasBeenIdleTooLong = function (timestamp, lastActivityTimestamp) {
            return Math.abs(timestamp - lastActivityTimestamp) > _this.sessionTimeoutMs;
        };
        if (!instance.persistence) {
            throw new Error('SessionIdManager requires a PostHogPersistence instance');
        }
        if (instance.config.cookieless_mode === 'always') {
            throw new Error('SessionIdManager cannot be used with cookieless_mode="always"');
        }
        this._config = instance.config;
        this._persistence = instance.persistence;
        this._windowId = undefined;
        this._sessionId = undefined;
        this._sessionStartTimestamp = null;
        this._sessionActivityTimestamp = null;
        this._sessionIdGenerator = sessionIdGenerator || uuidv7_1.uuidv7;
        this._windowIdGenerator = windowIdGenerator || uuidv7_1.uuidv7;
        var persistenceName = this._config['persistence_name'] || this._config['token'];
        var desiredTimeout = this._config['session_idle_timeout_seconds'] || exports.DEFAULT_SESSION_IDLE_TIMEOUT_SECONDS;
        this._sessionTimeoutMs =
            (0, core_1.clampToRange)(desiredTimeout, MIN_SESSION_IDLE_TIMEOUT_SECONDS, exports.MAX_SESSION_IDLE_TIMEOUT_SECONDS, logger.createLogger('session_idle_timeout_seconds'), exports.DEFAULT_SESSION_IDLE_TIMEOUT_SECONDS) * 1000;
        instance.register({ $configured_session_timeout_ms: this._sessionTimeoutMs });
        this._resetIdleTimer();
        this._window_id_storage_key = 'ph_' + persistenceName + '_window_id';
        this._primary_window_exists_storage_key = 'ph_' + persistenceName + '_primary_window_exists';
        // primary_window_exists is set when the DOM has been loaded and is cleared on unload
        // if it exists here it means there was no unload which suggests this window is opened as a tab duplication, window.open, etc.
        if (this._canUseSessionStorage()) {
            var lastWindowId = storage_1.sessionStore._parse(this._window_id_storage_key);
            var primaryWindowExists = storage_1.sessionStore._parse(this._primary_window_exists_storage_key);
            if (lastWindowId && !primaryWindowExists) {
                // Persist window from previous storage state
                this._windowId = lastWindowId;
            }
            else {
                // Wipe any reference to previous window id
                storage_1.sessionStore._remove(this._window_id_storage_key);
            }
            // Flag this session as having a primary window
            storage_1.sessionStore._set(this._primary_window_exists_storage_key, true);
        }
        if ((_a = this._config.bootstrap) === null || _a === void 0 ? void 0 : _a.sessionID) {
            try {
                var sessionStartTimestamp = (0, uuidv7_1.uuid7ToTimestampMs)(this._config.bootstrap.sessionID);
                this._setSessionId(this._config.bootstrap.sessionID, new Date().getTime(), sessionStartTimestamp);
            }
            catch (e) {
                logger.error('Invalid sessionID in bootstrap', e);
            }
        }
        this._listenToReloadWindow();
    }
    Object.defineProperty(SessionIdManager.prototype, "sessionTimeoutMs", {
        get: function () {
            return this._sessionTimeoutMs;
        },
        enumerable: false,
        configurable: true
    });
    SessionIdManager.prototype.onSessionId = function (callback) {
        var _this = this;
        // KLUDGE: when running in tests the handlers array was always undefined
        // it's yucky but safe to set it here so that it's always definitely available
        if ((0, core_1.isUndefined)(this._sessionIdChangedHandlers)) {
            this._sessionIdChangedHandlers = [];
        }
        this._sessionIdChangedHandlers.push(callback);
        if (this._sessionId) {
            callback(this._sessionId, this._windowId);
        }
        return function () {
            _this._sessionIdChangedHandlers = _this._sessionIdChangedHandlers.filter(function (h) { return h !== callback; });
        };
    };
    SessionIdManager.prototype._canUseSessionStorage = function () {
        // We only want to use sessionStorage if persistence is enabled and not memory storage
        return this._config.persistence !== 'memory' && !this._persistence._disabled && storage_1.sessionStore._is_supported();
    };
    // Note: this tries to store the windowId in sessionStorage. SessionStorage is unique to the current window/tab,
    // and persists page loads/reloads. So it's uniquely suited for storing the windowId. This function also respects
    // when persistence is disabled (by user config) and when sessionStorage is not supported (it *should* be supported on all browsers),
    // and in that case, it falls back to memory (which sadly, won't persist page loads)
    SessionIdManager.prototype._setWindowId = function (windowId) {
        if (windowId !== this._windowId) {
            this._windowId = windowId;
            if (this._canUseSessionStorage()) {
                storage_1.sessionStore._set(this._window_id_storage_key, windowId);
            }
        }
    };
    SessionIdManager.prototype._getWindowId = function () {
        if (this._windowId) {
            return this._windowId;
        }
        if (this._canUseSessionStorage()) {
            return storage_1.sessionStore._parse(this._window_id_storage_key);
        }
        // New window id will be generated
        return null;
    };
    // Note: 'this.persistence.register' can be disabled in the config.
    // In that case, this works by storing sessionId and the timestamp in memory.
    SessionIdManager.prototype._setSessionId = function (sessionId, sessionActivityTimestamp, sessionStartTimestamp) {
        var _a;
        if (sessionId !== this._sessionId ||
            sessionActivityTimestamp !== this._sessionActivityTimestamp ||
            sessionStartTimestamp !== this._sessionStartTimestamp) {
            this._sessionStartTimestamp = sessionStartTimestamp;
            this._sessionActivityTimestamp = sessionActivityTimestamp;
            this._sessionId = sessionId;
            this._persistence.register((_a = {},
                _a[constants_1.SESSION_ID] = [sessionActivityTimestamp, sessionId, sessionStartTimestamp],
                _a));
        }
    };
    SessionIdManager.prototype._getSessionId = function () {
        if (this._sessionId && this._sessionActivityTimestamp && this._sessionStartTimestamp) {
            return [this._sessionActivityTimestamp, this._sessionId, this._sessionStartTimestamp];
        }
        var sessionIdInfo = this._persistence.props[constants_1.SESSION_ID];
        if ((0, core_1.isArray)(sessionIdInfo) && sessionIdInfo.length === 2) {
            // Storage does not yet have a session start time. Add the last activity timestamp as the start time
            sessionIdInfo.push(sessionIdInfo[0]);
        }
        return sessionIdInfo || [0, null, 0];
    };
    // Resets the session id by setting it to null. On the subsequent call to checkAndGetSessionAndWindowId,
    // new ids will be generated.
    SessionIdManager.prototype.resetSessionId = function () {
        this._setSessionId(null, null, null);
    };
    /*
     * Listens to window unloads and removes the primaryWindowExists key from sessionStorage.
     * Reloaded or fresh tabs created after a DOM unloads (reloading the same tab) WILL NOT have this primaryWindowExists flag in session storage.
     * Cloned sessions (new tab, tab duplication, window.open(), ...) WILL have this primaryWindowExists flag in their copied session storage.
     * We conditionally check the primaryWindowExists value in the constructor to decide if the window id in the last session storage should be carried over.
     */
    SessionIdManager.prototype._listenToReloadWindow = function () {
        var _this = this;
        (0, utils_1.addEventListener)(globals_1.window, 'beforeunload', function () {
            if (_this._canUseSessionStorage()) {
                storage_1.sessionStore._remove(_this._primary_window_exists_storage_key);
            }
        }, 
        // Not making it passive to try and force the browser to handle this before the page is unloaded
        { capture: false });
    };
    /*
     * This function returns the current sessionId and windowId. It should be used to
     * access these values over directly calling `._sessionId` or `._windowId`.
     * In addition to returning the sessionId and windowId, this function also manages cycling the
     * sessionId and windowId when appropriate by doing the following:
     *
     * 1. If the sessionId or windowId is not set, it will generate a new one and store it.
     * 2. If the readOnly param is set to false, it will:
     *    a. Check if it has been > SESSION_CHANGE_THRESHOLD since the last call with this flag set.
     *       If so, it will generate a new sessionId and store it.
     *    b. Update the timestamp stored with the sessionId to ensure the current session is extended
     *       for the appropriate amount of time.
     *
     * @param {boolean} readOnly (optional) Defaults to False. Should be set to True when the call to the function should not extend or cycle the session (e.g. being called for non-user generated events)
     * @param {Number} timestamp (optional) Defaults to the current time. The timestamp to be stored with the sessionId (used when determining if a new sessionId should be generated)
     */
    SessionIdManager.prototype.checkAndGetSessionAndWindowId = function (readOnly, _timestamp) {
        if (readOnly === void 0) { readOnly = false; }
        if (_timestamp === void 0) { _timestamp = null; }
        if (this._config.cookieless_mode === 'always') {
            throw new Error('checkAndGetSessionAndWindowId should not be called with cookieless_mode="always"');
        }
        var timestamp = _timestamp || new Date().getTime();
        // eslint-disable-next-line prefer-const
        var _a = __read(this._getSessionId(), 3), lastActivityTimestamp = _a[0], sessionId = _a[1], startTimestamp = _a[2];
        var windowId = this._getWindowId();
        var sessionPastMaximumLength = (0, core_1.isNumber)(startTimestamp) &&
            startTimestamp > 0 &&
            Math.abs(timestamp - startTimestamp) > SESSION_LENGTH_LIMIT_MILLISECONDS;
        var valuesChanged = false;
        var noSessionId = !sessionId;
        var activityTimeout = !readOnly && this._sessionHasBeenIdleTooLong(timestamp, lastActivityTimestamp);
        if (noSessionId || activityTimeout || sessionPastMaximumLength) {
            sessionId = this._sessionIdGenerator();
            windowId = this._windowIdGenerator();
            logger.info('new session ID generated', {
                sessionId: sessionId,
                windowId: windowId,
                changeReason: { noSessionId: noSessionId, activityTimeout: activityTimeout, sessionPastMaximumLength: sessionPastMaximumLength },
            });
            startTimestamp = timestamp;
            valuesChanged = true;
        }
        else if (!windowId) {
            windowId = this._windowIdGenerator();
            valuesChanged = true;
        }
        var newActivityTimestamp = lastActivityTimestamp === 0 || !readOnly || sessionPastMaximumLength ? timestamp : lastActivityTimestamp;
        var sessionStartTimestamp = startTimestamp === 0 ? new Date().getTime() : startTimestamp;
        this._setWindowId(windowId);
        this._setSessionId(sessionId, newActivityTimestamp, sessionStartTimestamp);
        if (!readOnly) {
            this._resetIdleTimer();
        }
        if (valuesChanged) {
            this._sessionIdChangedHandlers.forEach(function (handler) {
                return handler(sessionId, windowId, valuesChanged ? { noSessionId: noSessionId, activityTimeout: activityTimeout, sessionPastMaximumLength: sessionPastMaximumLength } : undefined);
            });
        }
        return {
            sessionId: sessionId,
            windowId: windowId,
            sessionStartTimestamp: sessionStartTimestamp,
            changeReason: valuesChanged ? { noSessionId: noSessionId, activityTimeout: activityTimeout, sessionPastMaximumLength: sessionPastMaximumLength } : undefined,
            lastActivityTimestamp: lastActivityTimestamp,
        };
    };
    SessionIdManager.prototype._resetIdleTimer = function () {
        var _this = this;
        clearTimeout(this._enforceIdleTimeout);
        this._enforceIdleTimeout = setTimeout(function () {
            // enforce idle timeout a little after the session timeout to ensure the session is reset even without activity
            // we need to check session activity first in case a different window has kept the session active
            // while this window has been idle - and the timer has not progressed - e.g. window memory frozen while hidden
            var _a = __read(_this._getSessionId(), 1), lastActivityTimestamp = _a[0];
            if (_this._sessionHasBeenIdleTooLong(new Date().getTime(), lastActivityTimestamp)) {
                _this.resetSessionId();
            }
        }, this.sessionTimeoutMs * 1.1);
    };
    return SessionIdManager;
}());
exports.SessionIdManager = SessionIdManager;
//# sourceMappingURL=sessionid.js.map