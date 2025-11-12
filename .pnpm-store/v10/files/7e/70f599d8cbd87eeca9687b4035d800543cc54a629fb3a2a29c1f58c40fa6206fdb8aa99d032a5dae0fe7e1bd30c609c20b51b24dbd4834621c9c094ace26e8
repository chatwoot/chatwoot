"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
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
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SessionRecording = exports.SESSION_RECORDING_BATCH_KEY = exports.RECORDING_BUFFER_TIMEOUT = exports.RECORDING_MAX_EVENT_SIZE = exports.RECORDING_IDLE_THRESHOLD_MS = void 0;
var constants_1 = require("../../constants");
var sessionrecording_utils_1 = require("./sessionrecording-utils");
var types_1 = require("@rrweb/types");
var logger_1 = require("../../utils/logger");
var globals_1 = require("../../utils/globals");
var config_1 = require("./config");
var request_utils_1 = require("../../utils/request-utils");
var mutation_throttler_1 = require("./mutation-throttler");
var fflate_1 = require("fflate");
var core_1 = require("@posthog/core");
var config_2 = __importDefault(require("../../config"));
var utils_1 = require("../../utils");
var sampling_1 = require("../sampling");
var triggerMatching_1 = require("./triggerMatching");
var triggerMatching_2 = require("./triggerMatching");
var triggerMatching_3 = require("./triggerMatching");
var LOGGER_PREFIX = '[SessionRecording]';
var logger = (0, logger_1.createLogger)(LOGGER_PREFIX);
function getRRWebRecord() {
    var _a, _b;
    return (_b = (_a = globals_1.assignableWindow === null || globals_1.assignableWindow === void 0 ? void 0 : globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.rrweb) === null || _b === void 0 ? void 0 : _b.record;
}
var BASE_ENDPOINT = '/s/';
var ONE_MINUTE = 1000 * 60;
var FIVE_MINUTES = ONE_MINUTE * 5;
var TWO_SECONDS = 2000;
exports.RECORDING_IDLE_THRESHOLD_MS = FIVE_MINUTES;
var ONE_KB = 1024;
var PARTIAL_COMPRESSION_THRESHOLD = ONE_KB;
exports.RECORDING_MAX_EVENT_SIZE = ONE_KB * ONE_KB * 0.9; // ~1mb (with some wiggle room)
exports.RECORDING_BUFFER_TIMEOUT = 2000; // 2 seconds
exports.SESSION_RECORDING_BATCH_KEY = 'recordings';
var DEFAULT_CANVAS_QUALITY = 0.4;
var DEFAULT_CANVAS_FPS = 4;
var MAX_CANVAS_FPS = 12;
var MAX_CANVAS_QUALITY = 1;
var ACTIVE_SOURCES = [
    types_1.IncrementalSource.MouseMove,
    types_1.IncrementalSource.MouseInteraction,
    types_1.IncrementalSource.Scroll,
    types_1.IncrementalSource.ViewportResize,
    types_1.IncrementalSource.Input,
    types_1.IncrementalSource.TouchMove,
    types_1.IncrementalSource.MediaInteraction,
    types_1.IncrementalSource.Drag,
];
var newQueuedEvent = function (rrwebMethod) { return ({
    rrwebMethod: rrwebMethod,
    enqueuedAt: Date.now(),
    attempt: 1,
}); };
function gzipToString(data) {
    return (0, fflate_1.strFromU8)((0, fflate_1.gzipSync)((0, fflate_1.strToU8)(JSON.stringify(data))), true);
}
/**
 * rrweb's packer takes an event and returns a string or the reverse on `unpack`.
 * but we want to be able to inspect metadata during ingestion.
 * and don't want to compress the entire event,
 * so we have a custom packer that only compresses part of some events
 */
function compressEvent(event) {
    var originalSize = (0, sessionrecording_utils_1.estimateSize)(event);
    if (originalSize < PARTIAL_COMPRESSION_THRESHOLD) {
        return event;
    }
    try {
        if (event.type === types_1.EventType.FullSnapshot) {
            return __assign(__assign({}, event), { data: gzipToString(event.data), cv: '2024-10' });
        }
        if (event.type === types_1.EventType.IncrementalSnapshot && event.data.source === types_1.IncrementalSource.Mutation) {
            return __assign(__assign({}, event), { cv: '2024-10', data: __assign(__assign({}, event.data), { texts: gzipToString(event.data.texts), attributes: gzipToString(event.data.attributes), removes: gzipToString(event.data.removes), adds: gzipToString(event.data.adds) }) });
        }
        if (event.type === types_1.EventType.IncrementalSnapshot && event.data.source === types_1.IncrementalSource.StyleSheetRule) {
            return __assign(__assign({}, event), { cv: '2024-10', data: __assign(__assign({}, event.data), { adds: event.data.adds ? gzipToString(event.data.adds) : undefined, removes: event.data.removes ? gzipToString(event.data.removes) : undefined }) });
        }
    }
    catch (e) {
        logger.error('could not compress event - will use uncompressed event', e);
    }
    return event;
}
function isSessionIdleEvent(e) {
    return e.type === types_1.EventType.Custom && e.data.tag === 'sessionIdle';
}
/** When we put the recording into a paused state, we add a custom event.
 *  However, in the paused state, events are dropped and never make it to the buffer,
 *  so we need to manually let this one through */
function isRecordingPausedEvent(e) {
    return e.type === types_1.EventType.Custom && e.data.tag === 'recording paused';
}
var SessionRecording = /** @class */ (function () {
    function SessionRecording(_instance) {
        var _this = this;
        this._instance = _instance;
        this._statusMatcher = triggerMatching_1.nullMatchSessionRecordingStatus;
        this._receivedFlags = false;
        // and a queue - that contains rrweb events that we want to send to rrweb, but rrweb wasn't able to accept them yet
        this._queuedRRWebEvents = [];
        this._isIdle = 'unknown';
        this._lastActivityTimestamp = Date.now();
        // we need to be able to check the state of the event and url triggers separately
        // as we make some decisions based on them without referencing LinkedFlag etc
        this._triggerMatching = new triggerMatching_1.PendingTriggerMatching();
        this._removePageViewCaptureHook = undefined;
        this._onSessionIdListener = undefined;
        this._persistFlagsOnSessionListener = undefined;
        this._samplingSessionListener = undefined;
        this._removeEventTriggerCaptureHook = undefined;
        // Util to help developers working on this feature manually override
        this._forceAllowLocalhostNetworkCapture = false;
        this._onBeforeUnload = function () {
            _this._flushBuffer();
        };
        this._onOffline = function () {
            _this._tryAddCustomEvent('browser offline', {});
        };
        this._onOnline = function () {
            _this._tryAddCustomEvent('browser online', {});
        };
        this._onVisibilityChange = function () {
            if (globals_1.document === null || globals_1.document === void 0 ? void 0 : globals_1.document.visibilityState) {
                var label = 'window ' + globals_1.document.visibilityState;
                _this._tryAddCustomEvent(label, {});
            }
        };
        this._captureStarted = false;
        this._endpoint = BASE_ENDPOINT;
        this._stopRrweb = undefined;
        this._receivedFlags = false;
        if (!this._instance.sessionManager) {
            logger.error('started without valid sessionManager');
            throw new Error(LOGGER_PREFIX + ' started without valid sessionManager. This is a bug.');
        }
        if (this._instance.config.cookieless_mode === 'always') {
            throw new Error(LOGGER_PREFIX + ' cannot be used with cookieless_mode="always"');
        }
        this._linkedFlagMatching = new triggerMatching_1.LinkedFlagMatching(this._instance);
        this._urlTriggerMatching = new triggerMatching_3.URLTriggerMatching(this._instance);
        this._eventTriggerMatching = new triggerMatching_2.EventTriggerMatching(this._instance);
        // we know there's a sessionManager, so don't need to start without a session id
        var _a = this._sessionManager.checkAndGetSessionAndWindowId(), sessionId = _a.sessionId, windowId = _a.windowId;
        this._sessionId = sessionId;
        this._windowId = windowId;
        this._buffer = this._clearBuffer();
        if (this._sessionIdleThresholdMilliseconds >= this._sessionManager.sessionTimeoutMs) {
            logger.warn("session_idle_threshold_ms (".concat(this._sessionIdleThresholdMilliseconds, ") is greater than the session timeout (").concat(this._sessionManager.sessionTimeoutMs, "). Session will never be detected as idle"));
        }
    }
    Object.defineProperty(SessionRecording.prototype, "sessionId", {
        get: function () {
            return this._sessionId;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_sessionIdleThresholdMilliseconds", {
        get: function () {
            return this._instance.config.session_recording.session_idle_threshold_ms || exports.RECORDING_IDLE_THRESHOLD_MS;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "started", {
        get: function () {
            // TODO could we use status instead of _captureStarted?
            return this._captureStarted;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_sessionManager", {
        get: function () {
            if (!this._instance.sessionManager) {
                throw new Error(LOGGER_PREFIX + ' must be started with a valid sessionManager.');
            }
            return this._instance.sessionManager;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_fullSnapshotIntervalMillis", {
        get: function () {
            var _a, _b;
            if (this._triggerMatching.triggerStatus(this.sessionId) === triggerMatching_1.TRIGGER_PENDING) {
                return ONE_MINUTE;
            }
            return (_b = (_a = this._instance.config.session_recording) === null || _a === void 0 ? void 0 : _a.full_snapshot_interval_millis) !== null && _b !== void 0 ? _b : FIVE_MINUTES;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_isSampled", {
        get: function () {
            var currentValue = this._instance.get_property(constants_1.SESSION_RECORDING_IS_SAMPLED);
            return (0, core_1.isBoolean)(currentValue) ? currentValue : null;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_sessionDuration", {
        get: function () {
            var _a, _b;
            var mostRecentSnapshot = (_a = this._buffer) === null || _a === void 0 ? void 0 : _a.data[((_b = this._buffer) === null || _b === void 0 ? void 0 : _b.data.length) - 1];
            var sessionStartTimestamp = this._sessionManager.checkAndGetSessionAndWindowId(true).sessionStartTimestamp;
            return mostRecentSnapshot ? mostRecentSnapshot.timestamp - sessionStartTimestamp : null;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_isRecordingEnabled", {
        get: function () {
            var enabled_server_side = !!this._instance.get_property(constants_1.SESSION_RECORDING_ENABLED_SERVER_SIDE);
            var enabled_client_side = !this._instance.config.disable_session_recording;
            return globals_1.window && enabled_server_side && enabled_client_side;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_isConsoleLogCaptureEnabled", {
        get: function () {
            var enabled_server_side = !!this._instance.get_property(constants_1.CONSOLE_LOG_RECORDING_ENABLED_SERVER_SIDE);
            var enabled_client_side = this._instance.config.enable_recording_console_log;
            return enabled_client_side !== null && enabled_client_side !== void 0 ? enabled_client_side : enabled_server_side;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_canvasRecording", {
        get: function () {
            var _a, _b, _c, _d, _e, _f;
            var canvasRecording_client_side = this._instance.config.session_recording.captureCanvas;
            var canvasRecording_server_side = this._instance.get_property(constants_1.SESSION_RECORDING_CANVAS_RECORDING);
            var enabled = (_b = (_a = canvasRecording_client_side === null || canvasRecording_client_side === void 0 ? void 0 : canvasRecording_client_side.recordCanvas) !== null && _a !== void 0 ? _a : canvasRecording_server_side === null || canvasRecording_server_side === void 0 ? void 0 : canvasRecording_server_side.enabled) !== null && _b !== void 0 ? _b : false;
            var fps = (_d = (_c = canvasRecording_client_side === null || canvasRecording_client_side === void 0 ? void 0 : canvasRecording_client_side.canvasFps) !== null && _c !== void 0 ? _c : canvasRecording_server_side === null || canvasRecording_server_side === void 0 ? void 0 : canvasRecording_server_side.fps) !== null && _d !== void 0 ? _d : DEFAULT_CANVAS_FPS;
            var quality = (_f = (_e = canvasRecording_client_side === null || canvasRecording_client_side === void 0 ? void 0 : canvasRecording_client_side.canvasQuality) !== null && _e !== void 0 ? _e : canvasRecording_server_side === null || canvasRecording_server_side === void 0 ? void 0 : canvasRecording_server_side.quality) !== null && _f !== void 0 ? _f : DEFAULT_CANVAS_QUALITY;
            if (typeof quality === 'string') {
                var parsed = parseFloat(quality);
                quality = isNaN(parsed) ? 0.4 : parsed;
            }
            return {
                enabled: enabled,
                fps: (0, core_1.clampToRange)(fps, 0, MAX_CANVAS_FPS, logger.createLogger('canvas recording fps'), DEFAULT_CANVAS_FPS),
                quality: (0, core_1.clampToRange)(quality, 0, MAX_CANVAS_QUALITY, logger.createLogger('canvas recording quality'), DEFAULT_CANVAS_QUALITY),
            };
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_networkPayloadCapture", {
        // network payload capture config has three parts
        // each can be configured server side or client side
        get: function () {
            var _a, _b;
            var networkPayloadCapture_server_side = this._instance.get_property(constants_1.SESSION_RECORDING_NETWORK_PAYLOAD_CAPTURE);
            var networkPayloadCapture_client_side = {
                recordHeaders: (_a = this._instance.config.session_recording) === null || _a === void 0 ? void 0 : _a.recordHeaders,
                recordBody: (_b = this._instance.config.session_recording) === null || _b === void 0 ? void 0 : _b.recordBody,
            };
            var headersEnabled = (networkPayloadCapture_client_side === null || networkPayloadCapture_client_side === void 0 ? void 0 : networkPayloadCapture_client_side.recordHeaders) || (networkPayloadCapture_server_side === null || networkPayloadCapture_server_side === void 0 ? void 0 : networkPayloadCapture_server_side.recordHeaders);
            var bodyEnabled = (networkPayloadCapture_client_side === null || networkPayloadCapture_client_side === void 0 ? void 0 : networkPayloadCapture_client_side.recordBody) || (networkPayloadCapture_server_side === null || networkPayloadCapture_server_side === void 0 ? void 0 : networkPayloadCapture_server_side.recordBody);
            var clientConfigForPerformanceCapture = (0, core_1.isObject)(this._instance.config.capture_performance)
                ? this._instance.config.capture_performance.network_timing
                : this._instance.config.capture_performance;
            var networkTimingEnabled = !!((0, core_1.isBoolean)(clientConfigForPerformanceCapture)
                ? clientConfigForPerformanceCapture
                : networkPayloadCapture_server_side === null || networkPayloadCapture_server_side === void 0 ? void 0 : networkPayloadCapture_server_side.capturePerformance);
            return headersEnabled || bodyEnabled || networkTimingEnabled
                ? { recordHeaders: headersEnabled, recordBody: bodyEnabled, recordPerformance: networkTimingEnabled }
                : undefined;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_masking", {
        get: function () {
            var _a, _b, _c, _d, _e, _f;
            var masking_server_side = this._instance.get_property(constants_1.SESSION_RECORDING_MASKING);
            var masking_client_side = {
                maskAllInputs: (_a = this._instance.config.session_recording) === null || _a === void 0 ? void 0 : _a.maskAllInputs,
                maskTextSelector: (_b = this._instance.config.session_recording) === null || _b === void 0 ? void 0 : _b.maskTextSelector,
                blockSelector: (_c = this._instance.config.session_recording) === null || _c === void 0 ? void 0 : _c.blockSelector,
            };
            var maskAllInputs = (_d = masking_client_side === null || masking_client_side === void 0 ? void 0 : masking_client_side.maskAllInputs) !== null && _d !== void 0 ? _d : masking_server_side === null || masking_server_side === void 0 ? void 0 : masking_server_side.maskAllInputs;
            var maskTextSelector = (_e = masking_client_side === null || masking_client_side === void 0 ? void 0 : masking_client_side.maskTextSelector) !== null && _e !== void 0 ? _e : masking_server_side === null || masking_server_side === void 0 ? void 0 : masking_server_side.maskTextSelector;
            var blockSelector = (_f = masking_client_side === null || masking_client_side === void 0 ? void 0 : masking_client_side.blockSelector) !== null && _f !== void 0 ? _f : masking_server_side === null || masking_server_side === void 0 ? void 0 : masking_server_side.blockSelector;
            return !(0, core_1.isUndefined)(maskAllInputs) || !(0, core_1.isUndefined)(maskTextSelector) || !(0, core_1.isUndefined)(blockSelector)
                ? {
                    maskAllInputs: maskAllInputs !== null && maskAllInputs !== void 0 ? maskAllInputs : true,
                    maskTextSelector: maskTextSelector,
                    blockSelector: blockSelector,
                }
                : undefined;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_sampleRate", {
        get: function () {
            var rate = this._instance.get_property(constants_1.SESSION_RECORDING_SAMPLE_RATE);
            return (0, core_1.isNumber)(rate) ? rate : null;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "_minimumDuration", {
        get: function () {
            var duration = this._instance.get_property(constants_1.SESSION_RECORDING_MINIMUM_DURATION);
            return (0, core_1.isNumber)(duration) ? duration : null;
        },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SessionRecording.prototype, "status", {
        /**
         * defaults to buffering mode until a flags response is received
         * once a flags response is received status can be disabled, active or sampled
         */
        get: function () {
            if (!this._receivedFlags) {
                return triggerMatching_1.BUFFERING;
            }
            return this._statusMatcher({
                receivedFlags: this._receivedFlags,
                isRecordingEnabled: this._isRecordingEnabled,
                isSampled: this._isSampled,
                urlTriggerMatching: this._urlTriggerMatching,
                eventTriggerMatching: this._eventTriggerMatching,
                linkedFlagMatching: this._linkedFlagMatching,
                sessionId: this.sessionId,
            });
        },
        enumerable: false,
        configurable: true
    });
    SessionRecording.prototype.startIfEnabledOrStop = function (startReason) {
        var _this = this;
        if (this._isRecordingEnabled) {
            this._startCapture(startReason);
            // calling addEventListener multiple times is safe and will not add duplicates
            (0, utils_1.addEventListener)(globals_1.window, 'beforeunload', this._onBeforeUnload);
            (0, utils_1.addEventListener)(globals_1.window, 'offline', this._onOffline);
            (0, utils_1.addEventListener)(globals_1.window, 'online', this._onOnline);
            (0, utils_1.addEventListener)(globals_1.window, 'visibilitychange', this._onVisibilityChange);
            // on reload there might be an already sampled session that should be continued before flags response,
            // so we call this here _and_ in the flags response
            this._setupSampling();
            this._addEventTriggerListener();
            if ((0, core_1.isNullish)(this._removePageViewCaptureHook)) {
                // :TRICKY: rrweb does not capture navigation within SPA-s, so hook into our $pageview events to get access to all events.
                //   Dropping the initial event is fine (it's always captured by rrweb).
                this._removePageViewCaptureHook = this._instance.on('eventCaptured', function (event) {
                    // If anything could go wrong here,
                    // it has the potential to block the main loop,
                    // so we catch all errors.
                    try {
                        if (event.event === '$pageview') {
                            var href = (event === null || event === void 0 ? void 0 : event.properties.$current_url)
                                ? _this._maskUrl(event === null || event === void 0 ? void 0 : event.properties.$current_url)
                                : '';
                            if (!href) {
                                return;
                            }
                            _this._tryAddCustomEvent('$pageview', { href: href });
                        }
                    }
                    catch (e) {
                        logger.error('Could not add $pageview to rrweb session', e);
                    }
                });
            }
            if (!this._onSessionIdListener) {
                this._onSessionIdListener = this._sessionManager.onSessionId(function (sessionId, windowId, changeReason) {
                    var _a, _b, _c, _d;
                    if (changeReason) {
                        _this._tryAddCustomEvent('$session_id_change', { sessionId: sessionId, windowId: windowId, changeReason: changeReason });
                        (_b = (_a = _this._instance) === null || _a === void 0 ? void 0 : _a.persistence) === null || _b === void 0 ? void 0 : _b.unregister(constants_1.SESSION_RECORDING_EVENT_TRIGGER_ACTIVATED_SESSION);
                        (_d = (_c = _this._instance) === null || _c === void 0 ? void 0 : _c.persistence) === null || _d === void 0 ? void 0 : _d.unregister(constants_1.SESSION_RECORDING_URL_TRIGGER_ACTIVATED_SESSION);
                    }
                });
            }
        }
        else {
            this.stopRecording();
        }
    };
    SessionRecording.prototype.stopRecording = function () {
        var _a, _b, _c, _d;
        if (this._captureStarted && this._stopRrweb) {
            this._stopRrweb();
            this._stopRrweb = undefined;
            this._captureStarted = false;
            globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.removeEventListener('beforeunload', this._onBeforeUnload);
            globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.removeEventListener('offline', this._onOffline);
            globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.removeEventListener('online', this._onOnline);
            globals_1.window === null || globals_1.window === void 0 ? void 0 : globals_1.window.removeEventListener('visibilitychange', this._onVisibilityChange);
            this._clearBuffer();
            clearInterval(this._fullSnapshotTimer);
            (_a = this._removePageViewCaptureHook) === null || _a === void 0 ? void 0 : _a.call(this);
            this._removePageViewCaptureHook = undefined;
            (_b = this._removeEventTriggerCaptureHook) === null || _b === void 0 ? void 0 : _b.call(this);
            this._removeEventTriggerCaptureHook = undefined;
            (_c = this._onSessionIdListener) === null || _c === void 0 ? void 0 : _c.call(this);
            this._onSessionIdListener = undefined;
            (_d = this._samplingSessionListener) === null || _d === void 0 ? void 0 : _d.call(this);
            this._samplingSessionListener = undefined;
            this._eventTriggerMatching.stop();
            this._urlTriggerMatching.stop();
            this._linkedFlagMatching.stop();
            logger.info('stopped');
        }
    };
    SessionRecording.prototype._resetSampling = function () {
        var _a;
        (_a = this._instance.persistence) === null || _a === void 0 ? void 0 : _a.unregister(constants_1.SESSION_RECORDING_IS_SAMPLED);
    };
    SessionRecording.prototype._makeSamplingDecision = function (sessionId) {
        var _a;
        var _b;
        var sessionIdChanged = this._sessionId !== sessionId;
        // capture the current sample rate
        // because it is re-used multiple times
        // and the bundler won't minimize any of the references
        var currentSampleRate = this._sampleRate;
        if (!(0, core_1.isNumber)(currentSampleRate)) {
            this._resetSampling();
            return;
        }
        var storedIsSampled = this._isSampled;
        /**
         * if we get this far, then we should make a sampling decision.
         * When the session id changes or there is no stored sampling decision for this session id
         * then we should make a new decision.
         *
         * Otherwise, we should use the stored decision.
         */
        var makeDecision = sessionIdChanged || !(0, core_1.isBoolean)(storedIsSampled);
        var shouldSample = makeDecision ? (0, sampling_1.sampleOnProperty)(sessionId, currentSampleRate) : storedIsSampled;
        if (makeDecision) {
            if (shouldSample) {
                this._reportStarted(triggerMatching_1.SAMPLED);
            }
            else {
                logger.warn("Sample rate (".concat(currentSampleRate, ") has determined that this sessionId (").concat(sessionId, ") will not be sent to the server."));
            }
            this._tryAddCustomEvent('samplingDecisionMade', {
                sampleRate: currentSampleRate,
                isSampled: shouldSample,
            });
        }
        (_b = this._instance.persistence) === null || _b === void 0 ? void 0 : _b.register((_a = {},
            _a[constants_1.SESSION_RECORDING_IS_SAMPLED] = shouldSample,
            _a));
    };
    SessionRecording.prototype.onRemoteConfig = function (response) {
        var _this = this;
        var _a, _b, _c, _d;
        this._tryAddCustomEvent('$remote_config_received', response);
        this._persistRemoteConfig(response);
        if ((_a = response.sessionRecording) === null || _a === void 0 ? void 0 : _a.endpoint) {
            this._endpoint = (_b = response.sessionRecording) === null || _b === void 0 ? void 0 : _b.endpoint;
        }
        this._setupSampling();
        if (((_c = response.sessionRecording) === null || _c === void 0 ? void 0 : _c.triggerMatchType) === 'any') {
            this._statusMatcher = triggerMatching_1.anyMatchSessionRecordingStatus;
            this._triggerMatching = new triggerMatching_1.OrTriggerMatching([this._eventTriggerMatching, this._urlTriggerMatching]);
        }
        else {
            // either the setting is "ALL"
            // or we default to the most restrictive
            this._statusMatcher = triggerMatching_1.allMatchSessionRecordingStatus;
            this._triggerMatching = new triggerMatching_1.AndTriggerMatching([this._eventTriggerMatching, this._urlTriggerMatching]);
        }
        this._instance.register_for_session({
            $sdk_debug_replay_remote_trigger_matching_config: (_d = response.sessionRecording) === null || _d === void 0 ? void 0 : _d.triggerMatchType,
        });
        this._urlTriggerMatching.onRemoteConfig(response);
        this._eventTriggerMatching.onRemoteConfig(response);
        this._linkedFlagMatching.onRemoteConfig(response, function (flag, variant) {
            _this._reportStarted('linked_flag_matched', {
                flag: flag,
                variant: variant,
            });
        });
        this._receivedFlags = true;
        this.startIfEnabledOrStop();
    };
    /**
     * This might be called more than once so needs to be idempotent
     */
    SessionRecording.prototype._setupSampling = function () {
        var _this = this;
        if ((0, core_1.isNumber)(this._sampleRate) && (0, core_1.isNullish)(this._samplingSessionListener)) {
            this._samplingSessionListener = this._sessionManager.onSessionId(function (sessionId) {
                _this._makeSamplingDecision(sessionId);
            });
        }
    };
    SessionRecording.prototype._persistRemoteConfig = function (response) {
        var _this = this;
        var _a;
        if (this._instance.persistence) {
            var persistence_1 = this._instance.persistence;
            var persistResponse = function () {
                var _a;
                var _b, _c, _d, _e, _f, _g, _h, _j, _k;
                var receivedSampleRate = (_b = response.sessionRecording) === null || _b === void 0 ? void 0 : _b.sampleRate;
                var parsedSampleRate = (0, core_1.isNullish)(receivedSampleRate) ? null : parseFloat(receivedSampleRate);
                if ((0, core_1.isNullish)(parsedSampleRate)) {
                    _this._resetSampling();
                }
                var receivedMinimumDuration = (_c = response.sessionRecording) === null || _c === void 0 ? void 0 : _c.minimumDurationMilliseconds;
                persistence_1.register((_a = {},
                    _a[constants_1.SESSION_RECORDING_ENABLED_SERVER_SIDE] = !!response['sessionRecording'],
                    _a[constants_1.CONSOLE_LOG_RECORDING_ENABLED_SERVER_SIDE] = (_d = response.sessionRecording) === null || _d === void 0 ? void 0 : _d.consoleLogRecordingEnabled,
                    _a[constants_1.SESSION_RECORDING_NETWORK_PAYLOAD_CAPTURE] = __assign({ capturePerformance: response.capturePerformance }, (_e = response.sessionRecording) === null || _e === void 0 ? void 0 : _e.networkPayloadCapture),
                    _a[constants_1.SESSION_RECORDING_MASKING] = (_f = response.sessionRecording) === null || _f === void 0 ? void 0 : _f.masking,
                    _a[constants_1.SESSION_RECORDING_CANVAS_RECORDING] = {
                        enabled: (_g = response.sessionRecording) === null || _g === void 0 ? void 0 : _g.recordCanvas,
                        fps: (_h = response.sessionRecording) === null || _h === void 0 ? void 0 : _h.canvasFps,
                        quality: (_j = response.sessionRecording) === null || _j === void 0 ? void 0 : _j.canvasQuality,
                    },
                    _a[constants_1.SESSION_RECORDING_SAMPLE_RATE] = parsedSampleRate,
                    _a[constants_1.SESSION_RECORDING_MINIMUM_DURATION] = (0, core_1.isUndefined)(receivedMinimumDuration)
                        ? null
                        : receivedMinimumDuration,
                    _a[constants_1.SESSION_RECORDING_SCRIPT_CONFIG] = (_k = response.sessionRecording) === null || _k === void 0 ? void 0 : _k.scriptConfig,
                    _a));
            };
            persistResponse();
            // in case we see multiple flags responses, we should only use the response from the most recent one
            (_a = this._persistFlagsOnSessionListener) === null || _a === void 0 ? void 0 : _a.call(this);
            this._persistFlagsOnSessionListener = this._sessionManager.onSessionId(persistResponse);
        }
    };
    SessionRecording.prototype.log = function (message, level) {
        var _a;
        if (level === void 0) { level = 'log'; }
        (_a = this._instance.sessionRecording) === null || _a === void 0 ? void 0 : _a.onRRwebEmit({
            type: 6,
            data: {
                plugin: 'rrweb/console@1',
                payload: {
                    level: level,
                    trace: [],
                    // Even though it is a string, we stringify it as that's what rrweb expects
                    payload: [JSON.stringify(message)],
                },
            },
            timestamp: Date.now(),
        });
    };
    SessionRecording.prototype._startCapture = function (startReason) {
        var _this = this;
        var _a, _b;
        if ((0, core_1.isUndefined)(Object.assign) || (0, core_1.isUndefined)(Array.from)) {
            // According to the rrweb docs, rrweb is not supported on IE11 and below:
            // "rrweb does not support IE11 and below because it uses the MutationObserver API, which was supported by these browsers."
            // https://github.com/rrweb-io/rrweb/blob/master/guide.md#compatibility-note
            //
            // However, MutationObserver does exist on IE11, it just doesn't work well and does not detect all changes.
            // Instead, when we load "recorder.js", the first JS error is about "Object.assign" and "Array.from" being undefined.
            // Thus instead of MutationObserver, we look for this function and block recording if it's undefined.
            return;
        }
        // We do not switch recorder versions midway through a recording.
        // do not start if explicitly disabled or if the user has opted out
        if (this._captureStarted ||
            this._instance.config.disable_session_recording ||
            this._instance.consent.isOptedOut()) {
            return;
        }
        this._captureStarted = true;
        // We want to ensure the sessionManager is reset if necessary on loading the recorder
        this._sessionManager.checkAndGetSessionAndWindowId();
        // If recorder.js is already loaded (if array.full.js snippet is used or posthog-js/dist/recorder is
        // imported), don't load the script. Otherwise, remotely import recorder.js from cdn since it hasn't been loaded.
        if (!getRRWebRecord()) {
            (_b = (_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.loadExternalDependency) === null || _b === void 0 ? void 0 : _b.call(_a, this._instance, this._scriptName, function (err) {
                if (err) {
                    return logger.error('could not load recorder', err);
                }
                _this._onScriptLoaded();
            });
        }
        else {
            this._onScriptLoaded();
        }
        logger.info('starting');
        if (this.status === triggerMatching_2.ACTIVE) {
            this._reportStarted(startReason || 'recording_initialized');
        }
    };
    Object.defineProperty(SessionRecording.prototype, "_scriptName", {
        get: function () {
            var _a, _b, _c;
            return (((_c = (_b = (_a = this._instance) === null || _a === void 0 ? void 0 : _a.persistence) === null || _b === void 0 ? void 0 : _b.get_property(constants_1.SESSION_RECORDING_SCRIPT_CONFIG)) === null || _c === void 0 ? void 0 : _c.script) || 'recorder');
        },
        enumerable: false,
        configurable: true
    });
    SessionRecording.prototype._isInteractiveEvent = function (event) {
        var _a;
        return (event.type === sessionrecording_utils_1.INCREMENTAL_SNAPSHOT_EVENT_TYPE &&
            ACTIVE_SOURCES.indexOf((_a = event.data) === null || _a === void 0 ? void 0 : _a.source) !== -1);
    };
    SessionRecording.prototype._updateWindowAndSessionIds = function (event) {
        // Some recording events are triggered by non-user events (e.g. "X minutes ago" text updating on the screen).
        // We don't want to extend the session or trigger a new session in these cases. These events are designated by event
        // type -> incremental update, and source -> mutation.
        var isUserInteraction = this._isInteractiveEvent(event);
        if (!isUserInteraction && !this._isIdle) {
            // We check if the lastActivityTimestamp is old enough to go idle
            var timeSinceLastActivity = event.timestamp - this._lastActivityTimestamp;
            if (timeSinceLastActivity > this._sessionIdleThresholdMilliseconds) {
                // we mark as idle right away,
                // or else we get multiple idle events
                // if there are lots of non-user activity events being emitted
                this._isIdle = true;
                // don't take full snapshots while idle
                clearInterval(this._fullSnapshotTimer);
                this._tryAddCustomEvent('sessionIdle', {
                    eventTimestamp: event.timestamp,
                    lastActivityTimestamp: this._lastActivityTimestamp,
                    threshold: this._sessionIdleThresholdMilliseconds,
                    bufferLength: this._buffer.data.length,
                    bufferSize: this._buffer.size,
                });
                // proactively flush the buffer in case the session is idle for a long time
                this._flushBuffer();
            }
        }
        var returningFromIdle = false;
        if (isUserInteraction) {
            this._lastActivityTimestamp = event.timestamp;
            if (this._isIdle) {
                var idleWasUnknown = this._isIdle === 'unknown';
                // Remove the idle state
                this._isIdle = false;
                // if the idle state was unknown, we don't want to add an event, since we're just in bootup
                // whereas if it was true, we know we've been idle for a while, and we can mark ourselves as returning from idle
                if (!idleWasUnknown) {
                    this._tryAddCustomEvent('sessionNoLongerIdle', {
                        reason: 'user activity',
                        type: event.type,
                    });
                    returningFromIdle = true;
                }
            }
        }
        if (this._isIdle) {
            return;
        }
        // We only want to extend the session if it is an interactive event.
        var _a = this._sessionManager.checkAndGetSessionAndWindowId(!isUserInteraction, event.timestamp), windowId = _a.windowId, sessionId = _a.sessionId;
        var sessionIdChanged = this._sessionId !== sessionId;
        var windowIdChanged = this._windowId !== windowId;
        this._windowId = windowId;
        this._sessionId = sessionId;
        if (sessionIdChanged || windowIdChanged) {
            this.stopRecording();
            this.startIfEnabledOrStop('session_id_changed');
        }
        else if (returningFromIdle) {
            this._scheduleFullSnapshot();
        }
    };
    SessionRecording.prototype._tryRRWebMethod = function (queuedRRWebEvent) {
        try {
            queuedRRWebEvent.rrwebMethod();
            return true;
        }
        catch (e) {
            // Sometimes a race can occur where the recorder is not fully started yet
            if (this._queuedRRWebEvents.length < 10) {
                this._queuedRRWebEvents.push({
                    enqueuedAt: queuedRRWebEvent.enqueuedAt || Date.now(),
                    attempt: queuedRRWebEvent.attempt++,
                    rrwebMethod: queuedRRWebEvent.rrwebMethod,
                });
            }
            else {
                logger.warn('could not emit queued rrweb event.', e, queuedRRWebEvent);
            }
            return false;
        }
    };
    SessionRecording.prototype._tryAddCustomEvent = function (tag, payload) {
        return this._tryRRWebMethod(newQueuedEvent(function () { return getRRWebRecord().addCustomEvent(tag, payload); }));
    };
    SessionRecording.prototype._tryTakeFullSnapshot = function () {
        return this._tryRRWebMethod(newQueuedEvent(function () { return getRRWebRecord().takeFullSnapshot(); }));
    };
    SessionRecording.prototype._onScriptLoaded = function () {
        var e_1, _a;
        var _this = this;
        var _b, _c, _d, _e;
        // rrweb config info: https://github.com/rrweb-io/rrweb/blob/7d5d0033258d6c29599fb08412202d9a2c7b9413/src/record/index.ts#L28
        var sessionRecordingOptions = {
            // a limited set of the rrweb config options that we expose to our users.
            // see https://github.com/rrweb-io/rrweb/blob/master/guide.md
            blockClass: 'ph-no-capture',
            blockSelector: undefined,
            ignoreClass: 'ph-ignore-input',
            maskTextClass: 'ph-mask',
            maskTextSelector: undefined,
            maskTextFn: undefined,
            maskAllInputs: true,
            maskInputOptions: { password: true },
            maskInputFn: undefined,
            slimDOMOptions: {},
            collectFonts: false,
            inlineStylesheet: true,
            recordCrossOriginIframes: false,
        };
        // only allows user to set our allowlisted options
        var userSessionRecordingOptions = this._instance.config.session_recording;
        try {
            for (var _f = __values(Object.entries(userSessionRecordingOptions || {})), _g = _f.next(); !_g.done; _g = _f.next()) {
                var _h = __read(_g.value, 2), key = _h[0], value = _h[1];
                if (key in sessionRecordingOptions) {
                    if (key === 'maskInputOptions') {
                        // ensure password config is set if not included
                        sessionRecordingOptions.maskInputOptions = __assign({ password: true }, value);
                    }
                    else {
                        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                        // @ts-ignore
                        sessionRecordingOptions[key] = value;
                    }
                }
            }
        }
        catch (e_1_1) { e_1 = { error: e_1_1 }; }
        finally {
            try {
                if (_g && !_g.done && (_a = _f.return)) _a.call(_f);
            }
            finally { if (e_1) throw e_1.error; }
        }
        if (this._canvasRecording && this._canvasRecording.enabled) {
            sessionRecordingOptions.recordCanvas = true;
            sessionRecordingOptions.sampling = { canvas: this._canvasRecording.fps };
            sessionRecordingOptions.dataURLOptions = { type: 'image/webp', quality: this._canvasRecording.quality };
        }
        if (this._masking) {
            sessionRecordingOptions.maskAllInputs = (_b = this._masking.maskAllInputs) !== null && _b !== void 0 ? _b : true;
            sessionRecordingOptions.maskTextSelector = (_c = this._masking.maskTextSelector) !== null && _c !== void 0 ? _c : undefined;
            sessionRecordingOptions.blockSelector = (_d = this._masking.blockSelector) !== null && _d !== void 0 ? _d : undefined;
        }
        var rrwebRecord = getRRWebRecord();
        if (!rrwebRecord) {
            logger.error('onScriptLoaded was called but rrwebRecord is not available. This indicates something has gone wrong.');
            return;
        }
        this._mutationThrottler =
            (_e = this._mutationThrottler) !== null && _e !== void 0 ? _e : new mutation_throttler_1.MutationThrottler(rrwebRecord, {
                refillRate: this._instance.config.session_recording.__mutationThrottlerRefillRate,
                bucketSize: this._instance.config.session_recording.__mutationThrottlerBucketSize,
                onBlockedNode: function (id, node) {
                    var message = "Too many mutations on node '".concat(id, "'. Rate limiting. This could be due to SVG animations or something similar");
                    logger.info(message, {
                        node: node,
                    });
                    _this.log(LOGGER_PREFIX + ' ' + message, 'warn');
                },
            });
        var activePlugins = this._gatherRRWebPlugins();
        this._stopRrweb = rrwebRecord(__assign({ emit: function (event) {
                _this.onRRwebEmit(event);
            }, plugins: activePlugins }, sessionRecordingOptions));
        // We reset the last activity timestamp, resetting the idle timer
        this._lastActivityTimestamp = Date.now();
        // stay unknown if we're not sure if we're idle or not
        this._isIdle = (0, core_1.isBoolean)(this._isIdle) ? this._isIdle : 'unknown';
        this._tryAddCustomEvent('$session_options', {
            sessionRecordingOptions: sessionRecordingOptions,
            activePlugins: activePlugins.map(function (p) { return p === null || p === void 0 ? void 0 : p.name; }),
        });
        this._tryAddCustomEvent('$posthog_config', {
            config: this._instance.config,
        });
    };
    SessionRecording.prototype._scheduleFullSnapshot = function () {
        var _this = this;
        if (this._fullSnapshotTimer) {
            clearInterval(this._fullSnapshotTimer);
        }
        // we don't schedule snapshots while idle
        if (this._isIdle === true) {
            return;
        }
        var interval = this._fullSnapshotIntervalMillis;
        if (!interval) {
            return;
        }
        this._fullSnapshotTimer = setInterval(function () {
            _this._tryTakeFullSnapshot();
        }, interval);
    };
    SessionRecording.prototype._gatherRRWebPlugins = function () {
        var _a, _b, _c, _d;
        var plugins = [];
        var recordConsolePlugin = (_b = (_a = globals_1.assignableWindow.__PosthogExtensions__) === null || _a === void 0 ? void 0 : _a.rrwebPlugins) === null || _b === void 0 ? void 0 : _b.getRecordConsolePlugin;
        if (recordConsolePlugin && this._isConsoleLogCaptureEnabled) {
            plugins.push(recordConsolePlugin());
        }
        var networkPlugin = (_d = (_c = globals_1.assignableWindow.__PosthogExtensions__) === null || _c === void 0 ? void 0 : _c.rrwebPlugins) === null || _d === void 0 ? void 0 : _d.getRecordNetworkPlugin;
        if (this._networkPayloadCapture && (0, core_1.isFunction)(networkPlugin)) {
            var canRecordNetwork = !(0, request_utils_1.isLocalhost)() || this._forceAllowLocalhostNetworkCapture;
            if (canRecordNetwork) {
                plugins.push(networkPlugin((0, config_1.buildNetworkRequestOptions)(this._instance.config, this._networkPayloadCapture)));
            }
            else {
                logger.info('NetworkCapture not started because we are on localhost.');
            }
        }
        return plugins;
    };
    SessionRecording.prototype.onRRwebEmit = function (rawEvent) {
        var _this = this;
        var _a;
        this._processQueuedEvents();
        if (!rawEvent || !(0, core_1.isObject)(rawEvent)) {
            return;
        }
        if (rawEvent.type === types_1.EventType.Meta) {
            var href = this._maskUrl(rawEvent.data.href);
            this._lastHref = href;
            if (!href) {
                return;
            }
            rawEvent.data.href = href;
        }
        else {
            this._pageViewFallBack();
        }
        // Check if the URL matches any trigger patterns
        this._urlTriggerMatching.checkUrlTriggerConditions(function () { return _this._pauseRecording(); }, function () { return _this._resumeRecording(); }, function (triggerType) { return _this._activateTrigger(triggerType); });
        // always have to check if the URL is blocked really early,
        // or you risk getting stuck in a loop
        if (this._urlTriggerMatching.urlBlocked && !isRecordingPausedEvent(rawEvent)) {
            return;
        }
        // we're processing a full snapshot, so we should reset the timer
        if (rawEvent.type === types_1.EventType.FullSnapshot) {
            this._scheduleFullSnapshot();
        }
        // Clear the buffer if waiting for a trigger and only keep data from after the current full snapshot
        // we always start trigger pending so need to wait for flags before we know if we're really pending
        if (rawEvent.type === types_1.EventType.FullSnapshot &&
            this._receivedFlags &&
            this._triggerMatching.triggerStatus(this.sessionId) === triggerMatching_1.TRIGGER_PENDING) {
            this._clearBuffer();
        }
        var throttledEvent = this._mutationThrottler ? this._mutationThrottler.throttleMutations(rawEvent) : rawEvent;
        if (!throttledEvent) {
            return;
        }
        // TODO: Re-add ensureMaxMessageSize once we are confident in it
        var event = (0, sessionrecording_utils_1.truncateLargeConsoleLogs)(throttledEvent);
        this._updateWindowAndSessionIds(event);
        // When in an idle state we keep recording but don't capture the events,
        // we don't want to return early if idle is 'unknown'
        if (this._isIdle === true && !isSessionIdleEvent(event)) {
            return;
        }
        if (isSessionIdleEvent(event)) {
            // session idle events have a timestamp when rrweb sees them
            // which can artificially lengthen a session
            // we know when we detected it based on the payload and can correct the timestamp
            var payload = event.data.payload;
            if (payload) {
                var lastActivity = payload.lastActivityTimestamp;
                var threshold = payload.threshold;
                event.timestamp = lastActivity + threshold;
            }
        }
        var eventToSend = ((_a = this._instance.config.session_recording.compress_events) !== null && _a !== void 0 ? _a : true) ? compressEvent(event) : event;
        var size = (0, sessionrecording_utils_1.estimateSize)(eventToSend);
        var properties = {
            $snapshot_bytes: size,
            $snapshot_data: eventToSend,
            $session_id: this._sessionId,
            $window_id: this._windowId,
        };
        if (this.status === triggerMatching_1.DISABLED) {
            this._clearBuffer();
            return;
        }
        this._captureSnapshotBuffered(properties);
    };
    SessionRecording.prototype._pageViewFallBack = function () {
        if (this._instance.config.capture_pageview || !globals_1.window) {
            return;
        }
        var currentUrl = this._maskUrl(globals_1.window.location.href);
        if (this._lastHref !== currentUrl) {
            this._tryAddCustomEvent('$url_changed', { href: currentUrl });
            this._lastHref = currentUrl;
        }
    };
    SessionRecording.prototype._processQueuedEvents = function () {
        var _this = this;
        if (this._queuedRRWebEvents.length) {
            // if rrweb isn't ready to accept events earlier, then we queued them up.
            // now that `emit` has been called rrweb should be ready to accept them.
            // so, before we process this event, we try our queued events _once_ each
            // we don't want to risk queuing more things and never exiting this loop!
            // if they fail here, they'll be pushed into a new queue
            // and tried on the next loop.
            // there is a risk of this queue growing in an uncontrolled manner.
            // so its length is limited elsewhere
            // for now this is to help us ensure we can capture events that happen
            // and try to identify more about when it is failing
            var itemsToProcess = __spreadArray([], __read(this._queuedRRWebEvents), false);
            this._queuedRRWebEvents = [];
            itemsToProcess.forEach(function (queuedRRWebEvent) {
                if (Date.now() - queuedRRWebEvent.enqueuedAt <= TWO_SECONDS) {
                    _this._tryRRWebMethod(queuedRRWebEvent);
                }
            });
        }
    };
    SessionRecording.prototype._maskUrl = function (url) {
        var userSessionRecordingOptions = this._instance.config.session_recording;
        if (userSessionRecordingOptions.maskNetworkRequestFn) {
            var networkRequest = {
                url: url,
            };
            // TODO we should deprecate this and use the same function for this masking and the rrweb/network plugin
            // TODO or deprecate this and provide a new clearer name so this would be `maskURLPerformanceFn` or similar
            networkRequest = userSessionRecordingOptions.maskNetworkRequestFn(networkRequest);
            return networkRequest === null || networkRequest === void 0 ? void 0 : networkRequest.url;
        }
        return url;
    };
    SessionRecording.prototype._clearBuffer = function () {
        this._buffer = {
            size: 0,
            data: [],
            sessionId: this._sessionId,
            windowId: this._windowId,
        };
        return this._buffer;
    };
    SessionRecording.prototype._flushBuffer = function () {
        var _this = this;
        if (this._flushBufferTimer) {
            clearTimeout(this._flushBufferTimer);
            this._flushBufferTimer = undefined;
        }
        var minimumDuration = this._minimumDuration;
        var sessionDuration = this._sessionDuration;
        // if we have old data in the buffer but the session has rotated, then the
        // session duration might be negative. In that case we want to flush the buffer
        var isPositiveSessionDuration = (0, core_1.isNumber)(sessionDuration) && sessionDuration >= 0;
        var isBelowMinimumDuration = (0, core_1.isNumber)(minimumDuration) && isPositiveSessionDuration && sessionDuration < minimumDuration;
        if (this.status === triggerMatching_1.BUFFERING || this.status === triggerMatching_1.PAUSED || this.status === triggerMatching_1.DISABLED || isBelowMinimumDuration) {
            this._flushBufferTimer = setTimeout(function () {
                _this._flushBuffer();
            }, exports.RECORDING_BUFFER_TIMEOUT);
            return this._buffer;
        }
        if (this._buffer.data.length > 0) {
            var snapshotEvents = (0, sessionrecording_utils_1.splitBuffer)(this._buffer);
            snapshotEvents.forEach(function (snapshotBuffer) {
                _this._captureSnapshot({
                    $snapshot_bytes: snapshotBuffer.size,
                    $snapshot_data: snapshotBuffer.data,
                    $session_id: snapshotBuffer.sessionId,
                    $window_id: snapshotBuffer.windowId,
                    $lib: 'web',
                    $lib_version: config_2.default.LIB_VERSION,
                });
            });
        }
        // buffer is empty, we clear it in case the session id has changed
        return this._clearBuffer();
    };
    SessionRecording.prototype._captureSnapshotBuffered = function (properties) {
        var _this = this;
        var _a;
        var additionalBytes = 2 + (((_a = this._buffer) === null || _a === void 0 ? void 0 : _a.data.length) || 0); // 2 bytes for the array brackets and 1 byte for each comma
        if (!this._isIdle && // we never want to flush when idle
            (this._buffer.size + properties.$snapshot_bytes + additionalBytes > exports.RECORDING_MAX_EVENT_SIZE ||
                this._buffer.sessionId !== this._sessionId)) {
            this._buffer = this._flushBuffer();
        }
        this._buffer.size += properties.$snapshot_bytes;
        this._buffer.data.push(properties.$snapshot_data);
        if (!this._flushBufferTimer && !this._isIdle) {
            this._flushBufferTimer = setTimeout(function () {
                _this._flushBuffer();
            }, exports.RECORDING_BUFFER_TIMEOUT);
        }
    };
    SessionRecording.prototype._captureSnapshot = function (properties) {
        // :TRICKY: Make sure we batch these requests, use a custom endpoint and don't truncate the strings.
        this._instance.capture('$snapshot', properties, {
            _url: this._instance.requestRouter.endpointFor('api', this._endpoint),
            _noTruncate: true,
            _batchKey: exports.SESSION_RECORDING_BATCH_KEY,
            skip_client_rate_limiting: true,
        });
    };
    SessionRecording.prototype._activateTrigger = function (triggerType) {
        var _a;
        var _b, _c;
        if (this._triggerMatching.triggerStatus(this.sessionId) === triggerMatching_1.TRIGGER_PENDING) {
            // status is stored separately for URL and event triggers
            (_c = (_b = this._instance) === null || _b === void 0 ? void 0 : _b.persistence) === null || _c === void 0 ? void 0 : _c.register((_a = {},
                _a[triggerType === 'url'
                    ? constants_1.SESSION_RECORDING_URL_TRIGGER_ACTIVATED_SESSION
                    : constants_1.SESSION_RECORDING_EVENT_TRIGGER_ACTIVATED_SESSION] = this._sessionId,
                _a));
            this._flushBuffer();
            this._reportStarted((triggerType + '_trigger_matched'));
        }
    };
    SessionRecording.prototype._pauseRecording = function () {
        // we check _urlBlocked not status, since more than one thing can affect status
        if (this._urlTriggerMatching.urlBlocked) {
            return;
        }
        // we can't flush the buffer here since someone might be starting on a blocked page.
        // and we need to be sure that we don't record that page,
        // so we might not get the below custom event, but events will report the paused status.
        // which will allow debugging of sessions that start on blocked pages
        this._urlTriggerMatching.urlBlocked = true;
        // Clear the snapshot timer since we don't want new snapshots while paused
        clearInterval(this._fullSnapshotTimer);
        logger.info('recording paused due to URL blocker');
        this._tryAddCustomEvent('recording paused', { reason: 'url blocker' });
    };
    SessionRecording.prototype._resumeRecording = function () {
        // we check _urlBlocked not status, since more than one thing can affect status
        if (!this._urlTriggerMatching.urlBlocked) {
            return;
        }
        this._urlTriggerMatching.urlBlocked = false;
        this._tryTakeFullSnapshot();
        this._scheduleFullSnapshot();
        this._tryAddCustomEvent('recording resumed', { reason: 'left blocked url' });
        logger.info('recording resumed');
    };
    SessionRecording.prototype._addEventTriggerListener = function () {
        var _this = this;
        if (this._eventTriggerMatching._eventTriggers.length === 0 || !(0, core_1.isNullish)(this._removeEventTriggerCaptureHook)) {
            return;
        }
        this._removeEventTriggerCaptureHook = this._instance.on('eventCaptured', function (event) {
            // If anything could go wrong here, it has the potential to block the main loop,
            // so we catch all errors.
            try {
                if (_this._eventTriggerMatching._eventTriggers.includes(event.event)) {
                    _this._activateTrigger('event');
                }
            }
            catch (e) {
                logger.error('Could not activate event trigger', e);
            }
        });
    };
    /**
     * this ignores the linked flag config and (if other conditions are met) causes capture to start
     *
     * It is not usual to call this directly,
     * instead call `posthog.startSessionRecording({linked_flag: true})`
     * */
    SessionRecording.prototype.overrideLinkedFlag = function () {
        this._linkedFlagMatching.linkedFlagSeen = true;
        this._tryTakeFullSnapshot();
        this._reportStarted('linked_flag_overridden');
    };
    /**
     * this ignores the sampling config and (if other conditions are met) causes capture to start
     *
     * It is not usual to call this directly,
     * instead call `posthog.startSessionRecording({sampling: true})`
     * */
    SessionRecording.prototype.overrideSampling = function () {
        var _a;
        var _b;
        (_b = this._instance.persistence) === null || _b === void 0 ? void 0 : _b.register((_a = {},
            // short-circuits the `makeSamplingDecision` function in the session recording module
            _a[constants_1.SESSION_RECORDING_IS_SAMPLED] = true,
            _a));
        this._tryTakeFullSnapshot();
        this._reportStarted('sampling_overridden');
    };
    /**
     * this ignores the URL/Event trigger config and (if other conditions are met) causes capture to start
     *
     * It is not usual to call this directly,
     * instead call `posthog.startSessionRecording({trigger: 'url' | 'event'})`
     * */
    SessionRecording.prototype.overrideTrigger = function (triggerType) {
        this._activateTrigger(triggerType);
    };
    SessionRecording.prototype._reportStarted = function (startReason, tagPayload) {
        this._instance.register_for_session({
            $session_recording_start_reason: startReason,
        });
        logger.info(startReason.replace('_', ' '), tagPayload);
        if (!(0, core_1.includes)(['recording_initialized', 'session_id_changed'], startReason)) {
            this._tryAddCustomEvent(startReason, tagPayload);
        }
    };
    Object.defineProperty(SessionRecording.prototype, "sdkDebugProperties", {
        /*
         * whenever we capture an event, we add these properties to the event
         * these are used to debug issues with the session recording
         * when looking at the event feed for a session
         */
        get: function () {
            var sessionStartTimestamp = this._sessionManager.checkAndGetSessionAndWindowId(true).sessionStartTimestamp;
            return {
                $recording_status: this.status,
                $sdk_debug_replay_internal_buffer_length: this._buffer.data.length,
                $sdk_debug_replay_internal_buffer_size: this._buffer.size,
                $sdk_debug_current_session_duration: this._sessionDuration,
                $sdk_debug_session_start: sessionStartTimestamp,
            };
        },
        enumerable: false,
        configurable: true
    });
    return SessionRecording;
}());
exports.SessionRecording = SessionRecording;
//# sourceMappingURL=sessionrecording.js.map