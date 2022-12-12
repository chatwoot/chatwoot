Object.defineProperty(exports, "__esModule", { value: true });
var types_1 = require("@sentry/types");
var enums_1 = require("./enums");
function isSupportedSeverity(level) {
    return enums_1.SeverityLevels.indexOf(level) !== -1;
}
/**
 * Converts a string-based level into a {@link Severity}.
 *
 * @param level string representation of Severity
 * @returns Severity
 */
function severityFromString(level) {
    if (level === 'warn')
        return types_1.Severity.Warning;
    if (isSupportedSeverity(level)) {
        return level;
    }
    return types_1.Severity.Log;
}
exports.severityFromString = severityFromString;
//# sourceMappingURL=severity.js.map