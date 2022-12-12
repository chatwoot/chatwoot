"use strict";
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var os = __importStar(require("os"));
var chalk_1 = __importDefault(require("chalk"));
var issue_1 = require("../issue");
var InternalFormatter_1 = require("./InternalFormatter");
function createDefaultFormatter() {
    return function defaultFormatter(issue) {
        var color = {
            message: issue.severity === issue_1.IssueSeverity.WARNING
                ? chalk_1.default.bold.yellow
                : chalk_1.default.bold.red,
            position: chalk_1.default.bold.cyan,
            code: chalk_1.default.grey
        };
        if (issue.origin === issue_1.IssueOrigin.INTERNAL) {
            return InternalFormatter_1.createInternalFormatter()(issue);
        }
        var code = issue.origin === issue_1.IssueOrigin.TYPESCRIPT ? "TS" + issue.code : issue.code;
        return [
            color.message(issue.severity.toUpperCase() + " in ") +
                color.position(issue.file + "(" + issue.line + "," + issue.character + ")") +
                color.message(':'),
            color.code(code + ': ') + issue.message
        ].join(os.EOL);
    };
}
exports.createDefaultFormatter = createDefaultFormatter;
//# sourceMappingURL=DefaultFormatter.js.map