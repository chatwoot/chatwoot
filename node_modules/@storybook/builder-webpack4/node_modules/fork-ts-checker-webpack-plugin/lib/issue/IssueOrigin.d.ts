declare const IssueOrigin: {
    readonly TYPESCRIPT: "typescript";
    readonly ESLINT: "eslint";
    readonly INTERNAL: "internal";
};
declare type IssueOrigin = typeof IssueOrigin[keyof typeof IssueOrigin];
declare function isIssueOrigin(value: unknown): value is IssueOrigin;
declare function compareIssueOrigins(originA: IssueOrigin, originB: IssueOrigin): number;
export { IssueOrigin, isIssueOrigin, compareIssueOrigins };
