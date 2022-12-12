declare const IssueSeverity: {
    readonly ERROR: "error";
    readonly WARNING: "warning";
};
declare type IssueSeverity = typeof IssueSeverity[keyof typeof IssueSeverity];
declare function isIssueSeverity(value: unknown): value is IssueSeverity;
declare function compareIssueSeverities(severityA: IssueSeverity, severityB: IssueSeverity): number;
export { IssueSeverity, isIssueSeverity, compareIssueSeverities };
