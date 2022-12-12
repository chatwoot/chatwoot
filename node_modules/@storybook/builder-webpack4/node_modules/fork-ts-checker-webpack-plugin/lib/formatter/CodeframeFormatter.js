"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
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
var fs = __importStar(require("fs"));
var chalk_1 = __importDefault(require("chalk"));
var FsHelper_1 = require("../FsHelper");
var issue_1 = require("../issue");
var InternalFormatter_1 = require("./InternalFormatter");
var code_frame_1 = require("@babel/code-frame");
function createCodeframeFormatter(options) {
    return function codeframeFormatter(issue) {
        var color = {
            message: issue.severity === issue_1.IssueSeverity.WARNING
                ? chalk_1.default.bold.yellow
                : chalk_1.default.bold.red,
            position: chalk_1.default.dim
        };
        if (issue.origin === issue_1.IssueOrigin.INTERNAL) {
            return InternalFormatter_1.createInternalFormatter()(issue);
        }
        var file = issue.file;
        var source = file && FsHelper_1.fileExistsSync(file) && fs.readFileSync(file, 'utf-8');
        var frame = '';
        if (source) {
            frame = code_frame_1.codeFrameColumns(source, {
                start: {
                    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
                    line: issue.line,
                    column: issue.character
                }
            }, __assign({ highlightCode: true }, (options || {})))
                .split('\n')
                .map(function (line) { return '  ' + line; })
                .join(os.EOL);
        }
        var lines = [
            color.message(issue.severity.toUpperCase() + " in " + issue.file + "(" + issue.line + "," + issue.character + "):"),
            color.position(issue.line + ":" + issue.character + " " + issue.message)
        ];
        if (frame) {
            lines.push(frame);
        }
        return lines.join(os.EOL);
    };
}
exports.createCodeframeFormatter = createCodeframeFormatter;
//# sourceMappingURL=CodeframeFormatter.js.map