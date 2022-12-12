export interface LintMessage {
    column: number;
    line: number;
    endColumn?: number;
    endLine?: number;
    ruleId: string | null;
    message: string;
    nodeType: string;
    fatal?: true;
    severity: 0 | 1 | 2;
    fix?: {
        range: [number, number];
        text: string;
    };
    source: string | null;
}
export interface LintResult {
    filePath: string;
    messages: LintMessage[];
    errorCount: number;
    warningCount: number;
    fixableErrorCount: number;
    fixableWarningCount: number;
    output?: string;
    source?: string;
}
export interface LintReport {
    results: LintResult[];
    errorCount: number;
    warningCount: number;
    fixableErrorCount: number;
    fixableWarningCount: number;
}
export interface Options {
    fix?: boolean;
    [key: string]: any;
}
