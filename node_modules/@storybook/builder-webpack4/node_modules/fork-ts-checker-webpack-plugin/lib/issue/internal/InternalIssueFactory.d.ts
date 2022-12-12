import { Issue } from '../Issue';
interface ErrorLike {
    message?: string;
    stack?: string;
    toString?: () => string;
}
declare function createIssueFromInternalError(error: ErrorLike): Issue;
export { createIssueFromInternalError };
