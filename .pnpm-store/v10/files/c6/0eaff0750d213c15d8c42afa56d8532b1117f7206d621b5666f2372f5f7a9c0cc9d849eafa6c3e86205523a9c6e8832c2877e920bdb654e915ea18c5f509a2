"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.gracefulDecodeURIComponent = void 0;
/**
 * Tries to gets the unencoded version of an encoded component of a
 * Uniform Resource Identifier (URI). If input string is malformed,
 * returns it back as-is.
 *
 * Note: All occurences of the `+` character become ` ` (spaces).
 **/
function gracefulDecodeURIComponent(encodedURIComponent) {
    try {
        return decodeURIComponent(encodedURIComponent.replace(/\+/g, ' '));
    }
    catch (_a) {
        return encodedURIComponent;
    }
}
exports.gracefulDecodeURIComponent = gracefulDecodeURIComponent;
//# sourceMappingURL=gracefulDecodeURIComponent.js.map