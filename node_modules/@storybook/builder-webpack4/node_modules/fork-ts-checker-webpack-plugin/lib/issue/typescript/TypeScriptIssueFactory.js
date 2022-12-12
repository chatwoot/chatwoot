"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var Issue_1 = require("../Issue");
var IssueOrigin_1 = require("../IssueOrigin");
var IssueSeverity_1 = require("../IssueSeverity");
function createIssueFromTsDiagnostic(diagnostic, typescript) {
    var file;
    var line;
    var character;
    if (diagnostic.file) {
        file = diagnostic.file.fileName;
        if (diagnostic.start) {
            var position = diagnostic.file.getLineAndCharacterOfPosition(diagnostic.start);
            line = position.line + 1;
            character = position.character + 1;
        }
    }
    return {
        origin: IssueOrigin_1.IssueOrigin.TYPESCRIPT,
        code: String(diagnostic.code),
        // we don't handle Suggestion and Message diagnostics
        severity: diagnostic.category === 0 ? IssueSeverity_1.IssueSeverity.WARNING : IssueSeverity_1.IssueSeverity.ERROR,
        message: typescript.flattenDiagnosticMessageText(diagnostic.messageText, '\n'),
        file: file,
        line: line,
        character: character
    };
}
exports.createIssueFromTsDiagnostic = createIssueFromTsDiagnostic;
function createIssuesFromTsDiagnostics(diagnostics, typescript) {
    function createIssueFromTsDiagnosticWithFormatter(diagnostic) {
        return createIssueFromTsDiagnostic(diagnostic, typescript);
    }
    return Issue_1.deduplicateAndSortIssues(diagnostics.map(createIssueFromTsDiagnosticWithFormatter));
}
exports.createIssuesFromTsDiagnostics = createIssuesFromTsDiagnostics;
//# sourceMappingURL=TypeScriptIssueFactory.js.map