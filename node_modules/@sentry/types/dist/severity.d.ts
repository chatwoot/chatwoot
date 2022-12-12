/**
 * TODO(v7): Remove this enum and replace with SeverityLevel
 */
export declare enum Severity {
    /** JSDoc */
    Fatal = "fatal",
    /** JSDoc */
    Error = "error",
    /** JSDoc */
    Warning = "warning",
    /** JSDoc */
    Log = "log",
    /** JSDoc */
    Info = "info",
    /** JSDoc */
    Debug = "debug",
    /** JSDoc */
    Critical = "critical"
}
export declare const SeverityLevels: readonly ["fatal", "error", "warning", "log", "info", "debug", "critical"];
export declare type SeverityLevel = typeof SeverityLevels[number];
//# sourceMappingURL=severity.d.ts.map