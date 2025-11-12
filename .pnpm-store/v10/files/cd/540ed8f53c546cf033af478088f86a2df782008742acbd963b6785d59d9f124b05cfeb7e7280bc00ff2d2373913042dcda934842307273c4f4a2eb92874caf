"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isMatchingRegex = exports.isValidRegex = void 0;
var isValidRegex = function (str) {
    try {
        new RegExp(str);
    }
    catch (_a) {
        return false;
    }
    return true;
};
exports.isValidRegex = isValidRegex;
var isMatchingRegex = function (value, pattern) {
    if (!(0, exports.isValidRegex)(pattern))
        return false;
    try {
        return new RegExp(pattern).test(value);
    }
    catch (_a) {
        return false;
    }
};
exports.isMatchingRegex = isMatchingRegex;
//# sourceMappingURL=regex-utils.js.map