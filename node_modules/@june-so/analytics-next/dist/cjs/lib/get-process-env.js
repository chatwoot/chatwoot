"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getProcessEnv = void 0;
/**
 * Returns `process.env` if it is available in the environment.
 * Always returns an object make it similarly easy to use as `process.env`.
 */
function getProcessEnv() {
    if (typeof process === 'undefined' || !process.env) {
        return {};
    }
    return process.env;
}
exports.getProcessEnv = getProcessEnv;
//# sourceMappingURL=get-process-env.js.map