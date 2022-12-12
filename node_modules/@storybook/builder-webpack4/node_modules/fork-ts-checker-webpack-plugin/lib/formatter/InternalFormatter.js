"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
var chalk_1 = __importDefault(require("chalk"));
var os = __importStar(require("os"));
var issue_1 = require("../issue");
/**
 * TODO: maybe we should not treat internal errors as issues
 */
function createInternalFormatter() {
    return function internalFormatter(issue) {
        var color = {
            message: chalk_1.default.bold.red,
            stack: chalk_1.default.grey
        };
        if (issue.origin === issue_1.IssueOrigin.INTERNAL) {
            var lines = [
                color.message('INTERNAL ' + issue.severity.toUpperCase()) + ": " + issue.message
            ];
            if (issue.stack) {
                lines.push('stack trace:', color.stack(issue.stack));
            }
            return lines.join(os.EOL);
        }
        else {
            throw new Error("Not supported \"" + issue.origin + "\" issue origin.");
        }
    };
}
exports.createInternalFormatter = createInternalFormatter;
//# sourceMappingURL=InternalFormatter.js.map