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
Object.defineProperty(exports, "__esModule", { value: true });
const pluginHooks_1 = require("./pluginHooks");
const reporter_1 = require("../reporter");
const OperationCanceledError_1 = require("../error/OperationCanceledError");
const tapDoneToAsyncGetIssues_1 = require("./tapDoneToAsyncGetIssues");
const tapAfterCompileToGetIssues_1 = require("./tapAfterCompileToGetIssues");
const interceptDoneToGetWebpackDevServerTap_1 = require("./interceptDoneToGetWebpackDevServerTap");
const ForkTsCheckerWebpackPlugin_1 = require("../ForkTsCheckerWebpackPlugin");
function tapStartToConnectAndRunReporter(compiler, reporter, configuration, state) {
    const hooks = pluginHooks_1.getForkTsCheckerWebpackPluginHooks(compiler);
    compiler.hooks.run.tap('ForkTsCheckerWebpackPlugin', () => {
        if (!state.initialized) {
            state.initialized = true;
            state.watching = false;
            tapAfterCompileToGetIssues_1.tapAfterCompileToGetIssues(compiler, configuration, state);
        }
    });
    compiler.hooks.watchRun.tap('ForkTsCheckerWebpackPlugin', () => __awaiter(this, void 0, void 0, function* () {
        if (!state.initialized) {
            state.initialized = true;
            state.watching = true;
            if (configuration.async) {
                tapDoneToAsyncGetIssues_1.tapDoneToAsyncGetIssues(compiler, configuration, state);
                interceptDoneToGetWebpackDevServerTap_1.interceptDoneToGetWebpackDevServerTap(compiler, configuration, state);
            }
            else {
                tapAfterCompileToGetIssues_1.tapAfterCompileToGetIssues(compiler, configuration, state);
            }
        }
    }));
    compiler.hooks.compilation.tap('ForkTsCheckerWebpackPlugin', (compilation) => __awaiter(this, void 0, void 0, function* () {
        if (compilation.compiler !== compiler) {
            // run only for the compiler that the plugin was registered for
            return;
        }
        let change = {};
        if (state.watching) {
            change = reporter_1.getFilesChange(compiler);
            configuration.logger.infrastructure.info([
                'Calling reporter service for incremental check.',
                `  Changed files: ${JSON.stringify(change.changedFiles)}`,
                `  Deleted files: ${JSON.stringify(change.deletedFiles)}`,
            ].join('\n'));
        }
        else {
            configuration.logger.infrastructure.info('Calling reporter service for single check.');
        }
        let resolveDependencies;
        let rejectedDependencies;
        let resolveIssues;
        let rejectIssues;
        state.dependenciesPromise = new Promise((resolve, reject) => {
            resolveDependencies = resolve;
            rejectedDependencies = reject;
        });
        state.issuesPromise = new Promise((resolve, reject) => {
            resolveIssues = resolve;
            rejectIssues = reject;
        });
        const previousReportPromise = state.reportPromise;
        state.reportPromise = ForkTsCheckerWebpackPlugin_1.ForkTsCheckerWebpackPlugin.pool.submit((done) => new Promise((resolve) => __awaiter(this, void 0, void 0, function* () {
            change = yield hooks.start.promise(change, compilation);
            try {
                yield reporter.connect();
                const previousReport = yield previousReportPromise;
                if (previousReport) {
                    yield previousReport.close();
                }
                const report = yield reporter.getReport(change);
                resolve(report);
                report
                    .getDependencies()
                    .then(resolveDependencies)
                    .catch(rejectedDependencies)
                    .finally(() => {
                    // get issues after dependencies are resolved as it can be blocking
                    report.getIssues().then(resolveIssues).catch(rejectIssues).finally(done);
                });
            }
            catch (error) {
                if (error instanceof OperationCanceledError_1.OperationCanceledError) {
                    hooks.canceled.call(compilation);
                }
                else {
                    hooks.error.call(error, compilation);
                }
                resolve(undefined);
                resolveDependencies(undefined);
                resolveIssues(undefined);
                done();
            }
        })));
    }));
}
exports.tapStartToConnectAndRunReporter = tapStartToConnectAndRunReporter;
