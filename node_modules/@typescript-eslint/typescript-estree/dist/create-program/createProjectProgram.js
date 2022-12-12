"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createProjectProgram = void 0;
const debug_1 = __importDefault(require("debug"));
const path_1 = __importDefault(require("path"));
const ts = __importStar(require("typescript"));
const createWatchProgram_1 = require("./createWatchProgram");
const node_utils_1 = require("../node-utils");
const shared_1 = require("./shared");
const log = (0, debug_1.default)('typescript-eslint:typescript-estree:createProjectProgram');
const DEFAULT_EXTRA_FILE_EXTENSIONS = [
    ts.Extension.Ts,
    ts.Extension.Tsx,
    ts.Extension.Js,
    ts.Extension.Jsx,
    ts.Extension.Mjs,
    ts.Extension.Mts,
    ts.Extension.Cjs,
    ts.Extension.Cts,
];
/**
 * @param code The code of the file being linted
 * @param createDefaultProgram True if the default program should be created
 * @param extra The config object
 * @returns If found, returns the source file corresponding to the code and the containing program
 */
function createProjectProgram(code, createDefaultProgram, extra) {
    log('Creating project program for: %s', extra.filePath);
    const astAndProgram = (0, node_utils_1.firstDefined)((0, createWatchProgram_1.getProgramsForProjects)(code, extra.filePath, extra), currentProgram => (0, shared_1.getAstFromProgram)(currentProgram, extra));
    if (!astAndProgram && !createDefaultProgram) {
        // the file was either not matched within the tsconfig, or the extension wasn't expected
        const errorLines = [
            '"parserOptions.project" has been set for @typescript-eslint/parser.',
            `The file does not match your project config: ${path_1.default.relative(extra.tsconfigRootDir || process.cwd(), extra.filePath)}.`,
        ];
        let hasMatchedAnError = false;
        const extraFileExtensions = extra.extraFileExtensions || [];
        extraFileExtensions.forEach(extraExtension => {
            if (!extraExtension.startsWith('.')) {
                errorLines.push(`Found unexpected extension "${extraExtension}" specified with the "extraFileExtensions" option. Did you mean ".${extraExtension}"?`);
            }
            if (DEFAULT_EXTRA_FILE_EXTENSIONS.includes(extraExtension)) {
                errorLines.push(`You unnecessarily included the extension "${extraExtension}" with the "extraFileExtensions" option. This extension is already handled by the parser by default.`);
            }
        });
        const fileExtension = path_1.default.extname(extra.filePath);
        if (!DEFAULT_EXTRA_FILE_EXTENSIONS.includes(fileExtension)) {
            const nonStandardExt = `The extension for the file (${fileExtension}) is non-standard`;
            if (extraFileExtensions.length > 0) {
                if (!extraFileExtensions.includes(fileExtension)) {
                    errorLines.push(`${nonStandardExt}. It should be added to your existing "parserOptions.extraFileExtensions".`);
                    hasMatchedAnError = true;
                }
            }
            else {
                errorLines.push(`${nonStandardExt}. You should add "parserOptions.extraFileExtensions" to your config.`);
                hasMatchedAnError = true;
            }
        }
        if (!hasMatchedAnError) {
            errorLines.push('The file must be included in at least one of the projects provided.');
        }
        throw new Error(errorLines.join('\n'));
    }
    return astAndProgram;
}
exports.createProjectProgram = createProjectProgram;
//# sourceMappingURL=createProjectProgram.js.map