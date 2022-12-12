"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const EsLintIssueFactory_1 = require("../issue/EsLintIssueFactory");
const minimatch_1 = __importDefault(require("minimatch"));
function createEsLintReporter(configuration) {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const { CLIEngine } = require('eslint');
    const engine = new CLIEngine(configuration.options);
    let isInitialRun = true;
    const lintResults = new Map();
    const includedFilesPatterns = engine.resolveFileGlobPatterns(configuration.files);
    return {
        getReport: ({ changedFiles = [], deletedFiles = [] }) => __awaiter(this, void 0, void 0, function* () {
            return {
                getDependencies() {
                    return __awaiter(this, void 0, void 0, function* () {
                        return {
                            files: [],
                            dirs: [],
                            extensions: [],
                        };
                    });
                },
                getIssues() {
                    return __awaiter(this, void 0, void 0, function* () {
                        // cleanup old results
                        changedFiles.forEach((changedFile) => {
                            lintResults.delete(changedFile);
                        });
                        deletedFiles.forEach((removedFile) => {
                            lintResults.delete(removedFile);
                        });
                        // get reports
                        const lintReports = [];
                        if (isInitialRun) {
                            lintReports.push(engine.executeOnFiles(includedFilesPatterns));
                            isInitialRun = false;
                        }
                        else {
                            // we need to take care to not lint files that are not included by the configuration.
                            // the eslint engine will not exclude them automatically
                            const changedAndIncludedFiles = changedFiles.filter((changedFile) => includedFilesPatterns.some((includedFilesPattern) => minimatch_1.default(changedFile, includedFilesPattern)) &&
                                (configuration.options.extensions || []).some((extension) => changedFile.endsWith(extension)) &&
                                !engine.isPathIgnored(changedFile));
                            if (changedAndIncludedFiles.length) {
                                lintReports.push(engine.executeOnFiles(changedAndIncludedFiles));
                            }
                        }
                        // output fixes if `fix` option is provided
                        if (configuration.options.fix) {
                            yield Promise.all(lintReports.map((lintReport) => CLIEngine.outputFixes(lintReport)));
                        }
                        // store results
                        lintReports.forEach((lintReport) => {
                            lintReport.results.forEach((lintResult) => {
                                lintResults.set(lintResult.filePath, lintResult);
                            });
                        });
                        // get actual list of previous and current reports
                        const results = Array.from(lintResults.values());
                        return EsLintIssueFactory_1.createIssuesFromEsLintResults(results);
                    });
                },
                close() {
                    return __awaiter(this, void 0, void 0, function* () {
                        // do nothing
                    });
                },
            };
        }),
    };
}
exports.createEsLintReporter = createEsLintReporter;
