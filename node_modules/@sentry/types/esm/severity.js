/**
 * TODO(v7): Remove this enum and replace with SeverityLevel
 */
export var Severity;
(function (Severity) {
    /** JSDoc */
    Severity["Fatal"] = "fatal";
    /** JSDoc */
    Severity["Error"] = "error";
    /** JSDoc */
    Severity["Warning"] = "warning";
    /** JSDoc */
    Severity["Log"] = "log";
    /** JSDoc */
    Severity["Info"] = "info";
    /** JSDoc */
    Severity["Debug"] = "debug";
    /** JSDoc */
    Severity["Critical"] = "critical";
})(Severity || (Severity = {}));
// TODO: in v7, these can disappear, because they now also exist in `@sentry/utils`. (Having them there rather than here
// is nice because then it enforces the idea that only types are exported from `@sentry/types`.)
export var SeverityLevels = ['fatal', 'error', 'warning', 'log', 'info', 'debug', 'critical'];
//# sourceMappingURL=severity.js.map