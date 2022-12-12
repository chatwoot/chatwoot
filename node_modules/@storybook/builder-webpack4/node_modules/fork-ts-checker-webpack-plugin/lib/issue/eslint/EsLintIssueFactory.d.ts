import { Issue } from '../Issue';
import { LintReport } from '../../types/eslint';
declare function createIssuesFromEsLintReports(reports: LintReport[]): Issue[];
export { createIssuesFromEsLintReports };
