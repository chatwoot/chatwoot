"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parserOptionsToYAMLOption = void 0;
/**
 * ESLint parserOptions to `yaml`'s Composer options.
 */
function parserOptionsToYAMLOption(options) {
    if (!options) {
        return {};
    }
    const result = {};
    const version = options.defaultYAMLVersion;
    if (typeof version === "string" || typeof version === "number") {
        const sVer = String(version);
        if (sVer === "1.2" || sVer === "1.1") {
            result.version = sVer;
        }
        else {
            // Treat unknown versions as next.
            result.version = "next";
        }
    }
    return result;
}
exports.parserOptionsToYAMLOption = parserOptionsToYAMLOption;
