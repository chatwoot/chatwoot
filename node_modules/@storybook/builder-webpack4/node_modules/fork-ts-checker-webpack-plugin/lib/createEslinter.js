"use strict";
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
var path = __importStar(require("path"));
var FsHelper_1 = require("./FsHelper");
function createEslinter(eslintOptions) {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    var CLIEngine = require('eslint').CLIEngine;
    // See https://eslint.org/docs/developer-guide/nodejs-api#cliengine
    var eslinter = new CLIEngine(eslintOptions);
    function getReport(filepath) {
        try {
            if (eslinter.isPathIgnored(filepath) ||
                path.extname(filepath).localeCompare('.json', undefined, {
                    sensitivity: 'accent'
                }) === 0) {
                return undefined;
            }
            var lintReport = eslinter.executeOnFiles([filepath]);
            if (eslintOptions && eslintOptions.fix) {
                CLIEngine.outputFixes(lintReport);
            }
            return lintReport;
        }
        catch (e) {
            FsHelper_1.throwIfIsInvalidSourceFileError(filepath, e);
        }
        return undefined;
    }
    return { getReport: getReport };
}
exports.createEslinter = createEslinter;
//# sourceMappingURL=createEslinter.js.map