"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var IssueOrigin_1 = require("../IssueOrigin");
var IssueSeverity_1 = require("../IssueSeverity");
function createIssueFromInternalError(error) {
    return {
        origin: IssueOrigin_1.IssueOrigin.INTERNAL,
        severity: IssueSeverity_1.IssueSeverity.ERROR,
        code: 'INTERNAL',
        message: typeof error.message === 'string'
            ? error.message
            : (error.toString && error.toString()) || '',
        stack: typeof error.stack === 'string' ? error.stack : undefined
    };
}
exports.createIssueFromInternalError = createIssueFromInternalError;
//# sourceMappingURL=InternalIssueFactory.js.map