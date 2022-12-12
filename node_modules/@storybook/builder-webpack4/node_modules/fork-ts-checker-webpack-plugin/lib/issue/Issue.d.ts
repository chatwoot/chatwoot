import { IssueSeverity } from './IssueSeverity';
import { IssueOrigin } from './IssueOrigin';
interface Issue {
    origin: IssueOrigin;
    severity: IssueSeverity;
    code: string;
    message: string;
    file?: string;
    line?: number;
    character?: number;
    stack?: string;
}
declare function isIssue(value: unknown): value is Issue;
declare function deduplicateAndSortIssues(issues: Issue[]): Issue[];
export { Issue, isIssue, deduplicateAndSortIssues };
