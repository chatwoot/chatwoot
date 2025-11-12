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
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.appendArray = appendArray;
exports.updateThreshold = updateThreshold;
exports.simpleHash = simpleHash;
exports.sampleOnProperty = sampleOnProperty;
var core_1 = require("@posthog/core");
var logger_1 = require("../utils/logger");
function appendArray(currentValue, sampleType) {
    return __spreadArray(__spreadArray([], __read((currentValue ? currentValue : [])), false), __read(((0, core_1.isArray)(sampleType) ? sampleType : [sampleType])), false);
}
function updateThreshold(currentValue, percent) {
    return ((0, core_1.isUndefined)(currentValue) ? 1 : currentValue) * percent;
}
function simpleHash(str) {
    var hash = 0;
    for (var i = 0; i < str.length; i++) {
        hash = (hash << 5) - hash + str.charCodeAt(i); // (hash * 31) + char code
        hash |= 0; // Convert to 32bit integer
    }
    return Math.abs(hash);
}
/*
 * receives percent as a number between 0 and 1
 */
function sampleOnProperty(prop, percent) {
    return simpleHash(prop) % 100 < (0, core_1.clampToRange)(percent * 100, 0, 100, logger_1.logger);
}
//# sourceMappingURL=sampling.js.map