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
Object.defineProperty(exports, "__esModule", { value: true });
exports.printAndDropEverything = void 0;
exports.sampleByDistinctId = sampleByDistinctId;
exports.sampleBySessionId = sampleBySessionId;
exports.sampleByEvent = sampleByEvent;
var core_1 = require("@posthog/core");
var sampling_1 = require("../extensions/sampling");
var logger_1 = require("../utils/logger");
/**
 * Provides an implementation of sampling that samples based on the distinct ID.
 * Using the provided percentage.
 * Can be used to create a beforeCapture fn for a PostHog instance.
 *
 * Setting 0.5 will cause roughly 50% of distinct ids to have events sent.
 * Not 50% of events for each distinct id.
 *
 * @param percent a number from 0 to 1, 1 means always send and, 0 means never send the event
 */
function sampleByDistinctId(percent) {
    return function (captureResult) {
        if (!captureResult) {
            return null;
        }
        return (0, sampling_1.sampleOnProperty)(captureResult.properties.distinct_id, percent)
            ? __assign(__assign({}, captureResult), { properties: __assign(__assign({}, captureResult.properties), { $sample_type: ['sampleByDistinctId'], $sample_threshold: percent }) }) : null;
    };
}
/**
 * Provides an implementation of sampling that samples based on the session ID.
 * Using the provided percentage.
 * Can be used to create a beforeCapture fn for a PostHog instance.
 *
 * Setting 0.5 will cause roughly 50% of sessions to have events sent.
 * Not 50% of events for each session.
 *
 * @param percent a number from 0 to 1, 1 means always send and, 0 means never send the event
 */
function sampleBySessionId(percent) {
    return function (captureResult) {
        if (!captureResult) {
            return null;
        }
        return (0, sampling_1.sampleOnProperty)(captureResult.properties.$session_id, percent)
            ? __assign(__assign({}, captureResult), { properties: __assign(__assign({}, captureResult.properties), { $sample_type: (0, sampling_1.appendArray)(captureResult.properties.$sample_type, 'sampleBySessionId'), $sample_threshold: (0, sampling_1.updateThreshold)(captureResult.properties.$sample_threshold, percent) }) }) : null;
    };
}
/**
 * Provides an implementation of sampling that samples based on the event name.
 * Using the provided percentage.
 * Can be used to create a beforeCapture fn for a PostHog instance.
 *
 * @param eventNames an array of event names to sample, sampling is applied across events not per event name
 * @param percent a number from 0 to 1, 1 means always send, 0 means never send the event
 */
function sampleByEvent(eventNames, percent) {
    return function (captureResult) {
        var _a, _b, _c;
        if (!captureResult) {
            return null;
        }
        if (!(0, core_1.includes)(eventNames, captureResult.event)) {
            return captureResult;
        }
        var number = Math.random();
        return number * 100 < (0, core_1.clampToRange)(percent * 100, 0, 100, logger_1.logger)
            ? __assign(__assign({}, captureResult), { properties: __assign(__assign({}, captureResult.properties), { $sample_type: (0, sampling_1.appendArray)((_a = captureResult.properties) === null || _a === void 0 ? void 0 : _a.$sample_type, 'sampleByEvent'), $sample_threshold: (0, sampling_1.updateThreshold)((_b = captureResult.properties) === null || _b === void 0 ? void 0 : _b.$sample_threshold, percent), $sampled_events: (0, sampling_1.appendArray)((_c = captureResult.properties) === null || _c === void 0 ? void 0 : _c.$sampled_events, eventNames) }) }) : null;
    };
}
var printAndDropEverything = function (result) {
    // eslint-disable-next-line no-console
    console.log('Would have sent event:', result);
    return null;
};
exports.printAndDropEverything = printAndDropEverything;
//# sourceMappingURL=before-send.js.map