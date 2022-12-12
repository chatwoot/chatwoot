import * as ts from 'typescript';
import { Issue } from '../Issue';
declare function createIssueFromTsDiagnostic(diagnostic: ts.Diagnostic, typescript: typeof ts): Issue;
declare function createIssuesFromTsDiagnostics(diagnostics: ts.Diagnostic[], typescript: typeof ts): Issue[];
export { createIssueFromTsDiagnostic, createIssuesFromTsDiagnostics };
