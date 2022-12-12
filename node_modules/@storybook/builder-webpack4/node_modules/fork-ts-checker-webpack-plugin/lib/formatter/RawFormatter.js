"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var issue_1 = require("../issue");
function createRawFormatter() {
    return function rawFormatter(issue) {
        var code = issue.origin === issue_1.IssueOrigin.TYPESCRIPT ? "TS" + issue.code : issue.code;
        return issue.severity.toUpperCase() + " " + code + ": " + issue.message;
    };
}
exports.createRawFormatter = createRawFormatter;
//# sourceMappingURL=RawFormatter.js.map