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
var path = __importStar(require("path"));
var childProcess = __importStar(require("child_process"));
var semver = __importStar(require("semver"));
var micromatch_1 = __importDefault(require("micromatch"));
var chalk_1 = __importDefault(require("chalk"));
var worker_rpc_1 = require("worker-rpc");
var CancellationToken_1 = require("./CancellationToken");
var formatter_1 = require("./formatter");
var FsHelper_1 = require("./FsHelper");
var hooks_1 = require("./hooks");
var RpcTypes_1 = require("./RpcTypes");
var issue_1 = require("./issue");
var checkerPluginName = 'fork-ts-checker-webpack-plugin';
/**
 * ForkTsCheckerWebpackPlugin
 * Runs typescript type checker and linter on separate process.
 * This speed-ups build a lot.
 *
 * Options description in README.md
 */
var ForkTsCheckerWebpackPlugin = /** @class */ (function () {
    function ForkTsCheckerWebpackPlugin(options) {
        this.eslint = false;
        this.eslintOptions = {};
        this.tsconfigPath = undefined;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        this.compiler = undefined;
        this.started = undefined;
        this.elapsed = undefined;
        this.cancellationToken = undefined;
        this.isWatching = false;
        this.checkDone = false;
        this.compilationDone = false;
        this.diagnostics = [];
        this.lints = [];
        this.eslintVersion = undefined;
        this.startAt = 0;
        this.nodeArgs = [];
        options = options || {};
        this.options = __assign({}, options);
        this.ignoreDiagnostics = options.ignoreDiagnostics || [];
        this.ignoreLints = options.ignoreLints || [];
        this.ignoreLintWarnings = options.ignoreLintWarnings === true;
        this.reportFiles = options.reportFiles || [];
        this.logger = options.logger || console;
        this.silent = options.silent === true; // default false
        this.async = options.async !== false; // default true
        this.checkSyntacticErrors = options.checkSyntacticErrors === true; // default false
        this.resolveModuleNameModule = options.resolveModuleNameModule;
        this.resolveTypeReferenceDirectiveModule =
            options.resolveTypeReferenceDirectiveModule;
        this.memoryLimit =
            options.memoryLimit || ForkTsCheckerWebpackPlugin.DEFAULT_MEMORY_LIMIT;
        this.formatter = formatter_1.createFormatter(options.formatter, options.formatterOptions);
        this.rawFormatter = formatter_1.createRawFormatter();
        this.emitCallback = this.createNoopEmitCallback();
        this.doneCallback = this.createDoneCallback();
        var _a = this.validateTypeScript(options), typescript = _a.typescript, typescriptPath = _a.typescriptPath, typescriptVersion = _a.typescriptVersion, tsconfig = _a.tsconfig, compilerOptions = _a.compilerOptions;
        this.typescript = typescript;
        this.typescriptPath = typescriptPath;
        this.typescriptVersion = typescriptVersion;
        this.tsconfig = tsconfig;
        this.compilerOptions = compilerOptions;
        if (options.eslint === true) {
            var _b = this.validateEslint(options), eslintVersion = _b.eslintVersion, eslintOptions = _b.eslintOptions;
            this.eslint = true;
            this.eslintVersion = eslintVersion;
            this.eslintOptions = eslintOptions;
        }
        this.vue = ForkTsCheckerWebpackPlugin.prepareVueOptions(options.vue);
        this.useTypescriptIncrementalApi =
            options.useTypescriptIncrementalApi === undefined
                ? semver.gte(this.typescriptVersion, '3.0.0') && !this.vue.enabled
                : options.useTypescriptIncrementalApi;
        this.measureTime = options.measureCompilationTime === true;
        if (this.measureTime) {
            if (semver.lt(process.version, '8.5.0')) {
                throw new Error("To use 'measureCompilationTime' option, please update to Node.js >= v8.5.0 " +
                    ("(current version is " + process.version + ")"));
            }
            // Node 8+ only
            // eslint-disable-next-line node/no-unsupported-features/node-builtins
            this.performance = require('perf_hooks').performance;
        }
    }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ForkTsCheckerWebpackPlugin.getCompilerHooks = function (compiler) {
        return hooks_1.getForkTsCheckerWebpackPluginHooks(compiler);
    };
    ForkTsCheckerWebpackPlugin.prototype.validateTypeScript = function (options) {
        var typescriptPath = options.typescript || require.resolve('typescript');
        var tsconfig = options.tsconfig || './tsconfig.json';
        var compilerOptions = typeof options.compilerOptions === 'object'
            ? options.compilerOptions
            : {};
        var typescript, typescriptVersion;
        try {
            typescript = require(typescriptPath);
            typescriptVersion = typescript.version;
        }
        catch (_ignored) {
            throw new Error('When you use this plugin you must install `typescript`.');
        }
        if (semver.lt(typescriptVersion, '2.1.0')) {
            throw new Error("Cannot use current typescript version of " + typescriptVersion + ", the minimum required version is 2.1.0");
        }
        return {
            typescriptPath: typescriptPath,
            typescript: typescript,
            typescriptVersion: typescriptVersion,
            tsconfig: tsconfig,
            compilerOptions: compilerOptions
        };
    };
    ForkTsCheckerWebpackPlugin.prototype.validateEslint = function (options) {
        var eslintVersion;
        var eslintOptions = typeof options.eslintOptions === 'object' ? options.eslintOptions : {};
        if (semver.lt(process.version, '8.10.0')) {
            throw new Error("To use 'eslint' option, please update to Node.js >= v8.10.0 " +
                ("(current version is " + process.version + ")"));
        }
        try {
            eslintVersion = require('eslint').Linter.version;
        }
        catch (error) {
            throw new Error("When you use 'eslint' option, make sure to install 'eslint'.");
        }
        return { eslintVersion: eslintVersion, eslintOptions: eslintOptions };
    };
    ForkTsCheckerWebpackPlugin.prepareVueOptions = function (vueOptions) {
        var defaultVueOptions = {
            compiler: 'vue-template-compiler',
            enabled: false
        };
        if (typeof vueOptions === 'boolean') {
            return Object.assign(defaultVueOptions, { enabled: vueOptions });
        }
        else if (typeof vueOptions === 'object' && vueOptions !== null) {
            return Object.assign(defaultVueOptions, vueOptions);
        }
        else {
            return defaultVueOptions;
        }
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    ForkTsCheckerWebpackPlugin.prototype.apply = function (compiler) {
        this.compiler = compiler;
        this.tsconfigPath = this.computeContextPath(this.tsconfig);
        // validate config
        var tsconfigOk = FsHelper_1.fileExistsSync(this.tsconfigPath);
        // validate logger
        if (this.logger) {
            if (!this.logger.error || !this.logger.warn || !this.logger.info) {
                throw new Error("Invalid logger object - doesn't provide `error`, `warn` or `info` method.");
            }
        }
        if (!tsconfigOk) {
            throw new Error('Cannot find "' +
                this.tsconfigPath +
                '" file. Please check webpack and ForkTsCheckerWebpackPlugin configuration. \n' +
                'Possible errors: \n' +
                '  - wrong `context` directory in webpack configuration' +
                ' (if `tsconfig` is not set or is a relative path in fork plugin configuration)\n' +
                '  - wrong `tsconfig` path in fork plugin configuration' +
                ' (should be a relative or absolute path)');
        }
        this.pluginStart();
        this.pluginStop();
        this.pluginCompile();
        this.pluginEmit();
        this.pluginDone();
    };
    ForkTsCheckerWebpackPlugin.prototype.computeContextPath = function (filePath) {
        return path.isAbsolute(filePath)
            ? filePath
            : path.resolve(this.compiler.options.context, filePath);
    };
    ForkTsCheckerWebpackPlugin.prototype.pluginStart = function () {
        var _this = this;
        var run = function (compilation, callback) {
            _this.isWatching = false;
            callback();
        };
        var watchRun = function (compiler, callback) {
            _this.isWatching = true;
            callback();
        };
        this.compiler.hooks.run.tapAsync(checkerPluginName, run);
        this.compiler.hooks.watchRun.tapAsync(checkerPluginName, watchRun);
    };
    ForkTsCheckerWebpackPlugin.prototype.pluginStop = function () {
        var _this = this;
        var watchClose = function () {
            _this.killService();
        };
        var doneOrFailed = function () {
            if (!_this.isWatching) {
                _this.killService();
            }
        };
        this.compiler.hooks.watchClose.tap(checkerPluginName, watchClose);
        this.compiler.hooks.done.tap(checkerPluginName, doneOrFailed);
        this.compiler.hooks.failed.tap(checkerPluginName, doneOrFailed);
        process.on('exit', function () {
            _this.killService();
        });
    };
    ForkTsCheckerWebpackPlugin.prototype.pluginCompile = function () {
        var _this = this;
        var forkTsCheckerHooks = ForkTsCheckerWebpackPlugin.getCompilerHooks(this.compiler);
        this.compiler.hooks.compile.tap(checkerPluginName, function () {
            _this.compilationDone = false;
            forkTsCheckerHooks.serviceBeforeStart.callAsync(function () {
                if (_this.cancellationToken) {
                    // request cancellation if there is not finished job
                    _this.cancellationToken.requestCancellation();
                    forkTsCheckerHooks.cancel.call(_this.cancellationToken);
                }
                _this.checkDone = false;
                _this.started = process.hrtime();
                // create new token for current job
                _this.cancellationToken = new CancellationToken_1.CancellationToken(_this.typescript);
                if (!_this.service || !_this.service.connected) {
                    _this.spawnService();
                }
                try {
                    if (_this.measureTime) {
                        _this.startAt = _this.performance.now();
                    }
                    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
                    _this.serviceRpc.rpc(RpcTypes_1.RUN, _this.cancellationToken.toJSON()).then(function (result) {
                        if (result) {
                            _this.handleServiceMessage(result);
                        }
                    });
                }
                catch (error) {
                    if (!_this.silent && _this.logger) {
                        _this.logger.error(chalk_1.default.red('Cannot start checker service: ' +
                            (error ? error.toString() : 'Unknown error')));
                    }
                    forkTsCheckerHooks.serviceStartError.call(error);
                }
            });
        });
    };
    ForkTsCheckerWebpackPlugin.prototype.pluginEmit = function () {
        var _this = this;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        var emit = function (compilation, callback) {
            if (_this.isWatching && _this.async) {
                callback();
                return;
            }
            _this.emitCallback = _this.createEmitCallback(compilation, callback);
            if (_this.checkDone) {
                _this.emitCallback();
            }
            _this.compilationDone = true;
        };
        this.compiler.hooks.emit.tapAsync(checkerPluginName, emit);
    };
    ForkTsCheckerWebpackPlugin.prototype.pluginDone = function () {
        var _this = this;
        var forkTsCheckerHooks = ForkTsCheckerWebpackPlugin.getCompilerHooks(this.compiler);
        this.compiler.hooks.done.tap(checkerPluginName, function () {
            if (!_this.isWatching || !_this.async) {
                return;
            }
            if (_this.checkDone) {
                _this.doneCallback();
            }
            else {
                if (_this.compiler) {
                    forkTsCheckerHooks.waiting.call();
                }
                if (!_this.silent && _this.logger) {
                    _this.logger.info('Type checking in progress...');
                }
            }
            _this.compilationDone = true;
        });
    };
    ForkTsCheckerWebpackPlugin.prototype.spawnService = function () {
        var _this = this;
        var env = __assign({}, process.env, { TYPESCRIPT_PATH: this.typescriptPath, TSCONFIG: this.tsconfigPath, COMPILER_OPTIONS: JSON.stringify(this.compilerOptions), CONTEXT: this.compiler.options.context, ESLINT: String(this.eslint), ESLINT_OPTIONS: JSON.stringify(this.eslintOptions), MEMORY_LIMIT: String(this.memoryLimit), CHECK_SYNTACTIC_ERRORS: String(this.checkSyntacticErrors), USE_INCREMENTAL_API: String(this.useTypescriptIncrementalApi === true), VUE: JSON.stringify(this.vue) });
        if (typeof this.resolveModuleNameModule !== 'undefined') {
            env.RESOLVE_MODULE_NAME = this.resolveModuleNameModule;
        }
        else {
            delete env.RESOLVE_MODULE_NAME;
        }
        if (typeof this.resolveTypeReferenceDirectiveModule !== 'undefined') {
            env.RESOLVE_TYPE_REFERENCE_DIRECTIVE = this.resolveTypeReferenceDirectiveModule;
        }
        else {
            delete env.RESOLVE_TYPE_REFERENCE_DIRECTIVE;
        }
        this.service = childProcess.fork(path.resolve(__dirname, './service.js'), [], {
            env: env,
            execArgv: ['--max-old-space-size=' + this.memoryLimit].concat(this.nodeArgs),
            stdio: ['inherit', 'inherit', 'inherit', 'ipc']
        });
        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        this.serviceRpc = new worker_rpc_1.RpcProvider(function (message) { return _this.service.send(message); });
        this.service.on('message', function (message) {
            if (_this.serviceRpc) {
                // ensure that serviceRpc is defined to avoid race-conditions
                _this.serviceRpc.dispatch(message);
            }
        });
        var forkTsCheckerHooks = ForkTsCheckerWebpackPlugin.getCompilerHooks(this.compiler);
        forkTsCheckerHooks.serviceStart.call(this.tsconfigPath, this.memoryLimit);
        if (!this.silent && this.logger) {
            this.logger.info('Starting type checking service...');
        }
        this.service.on('exit', function (code, signal) {
            return _this.handleServiceExit(code, signal);
        });
    };
    ForkTsCheckerWebpackPlugin.prototype.killService = function () {
        if (!this.service) {
            return;
        }
        try {
            if (this.cancellationToken) {
                this.cancellationToken.cleanupCancellation();
            }
            // clean-up listeners
            this.service.removeAllListeners();
            this.service.kill();
            this.service = undefined;
            this.serviceRpc = undefined;
        }
        catch (e) {
            if (this.logger && !this.silent) {
                this.logger.error(e);
            }
        }
    };
    ForkTsCheckerWebpackPlugin.prototype.handleServiceMessage = function (message) {
        var _this = this;
        if (this.measureTime) {
            var delta = this.performance.now() - this.startAt;
            var deltaRounded = Math.round(delta * 100) / 100;
            this.logger.info("Compilation took: " + deltaRounded + " ms.");
        }
        if (this.cancellationToken) {
            this.cancellationToken.cleanupCancellation();
            // job is done - nothing to cancel
            this.cancellationToken = undefined;
        }
        this.checkDone = true;
        this.elapsed = process.hrtime(this.started);
        this.diagnostics = message.diagnostics;
        this.lints = message.lints;
        if (this.ignoreDiagnostics.length) {
            this.diagnostics = this.diagnostics.filter(function (diagnostic) {
                return !_this.ignoreDiagnostics.includes(parseInt(diagnostic.code, 10));
            });
        }
        if (this.ignoreLints.length) {
            this.lints = this.lints.filter(function (lint) { return !_this.ignoreLints.includes(lint.code); });
        }
        if (this.reportFiles.length) {
            var reportFilesPredicate = function (issue) {
                if (issue.file) {
                    var relativeFileName = path.relative(_this.compiler.options.context, issue.file);
                    var matchResult = micromatch_1.default([relativeFileName], _this.reportFiles);
                    if (matchResult.length === 0) {
                        return false;
                    }
                }
                return true;
            };
            this.diagnostics = this.diagnostics.filter(reportFilesPredicate);
            this.lints = this.lints.filter(reportFilesPredicate);
        }
        var forkTsCheckerHooks = ForkTsCheckerWebpackPlugin.getCompilerHooks(this.compiler);
        forkTsCheckerHooks.receive.call(this.diagnostics, this.lints);
        if (this.compilationDone) {
            this.isWatching && this.async ? this.doneCallback() : this.emitCallback();
        }
    };
    ForkTsCheckerWebpackPlugin.prototype.handleServiceExit = function (_code, signal) {
        if (signal !== 'SIGABRT' && signal !== 'SIGINT') {
            return;
        }
        // probably out of memory :/
        if (this.compiler) {
            var forkTsCheckerHooks = ForkTsCheckerWebpackPlugin.getCompilerHooks(this.compiler);
            forkTsCheckerHooks.serviceOutOfMemory.call();
        }
        if (!this.silent && this.logger) {
            if (signal === 'SIGINT') {
                this.logger.error(chalk_1.default.red('Type checking and linting interrupted - If running in a docker container, this may be caused ' +
                    "by the container running out of memory. If so, try increasing the container's memory limit " +
                    'or lowering the memoryLimit value in the ForkTsCheckerWebpackPlugin configuration.'));
            }
            else {
                this.logger.error(chalk_1.default.red('Type checking and linting aborted - probably out of memory. ' +
                    'Check `memoryLimit` option in ForkTsCheckerWebpackPlugin configuration.'));
            }
        }
    };
    ForkTsCheckerWebpackPlugin.prototype.createEmitCallback = function (compilation, callback) {
        return function emitCallback() {
            var _this = this;
            if (!this.elapsed) {
                throw new Error('Execution order error');
            }
            var elapsed = Math.round(this.elapsed[0] * 1e9 + this.elapsed[1]);
            var forkTsCheckerHooks = ForkTsCheckerWebpackPlugin.getCompilerHooks(this.compiler);
            forkTsCheckerHooks.emit.call(this.diagnostics, this.lints, elapsed);
            this.diagnostics.concat(this.lints).forEach(function (issue) {
                // webpack message format
                var formatted = {
                    rawMessage: _this.rawFormatter(issue),
                    message: _this.formatter(issue),
                    location: {
                        line: issue.line,
                        character: issue.character
                    },
                    file: issue.file
                };
                if (issue.severity === issue_1.IssueSeverity.WARNING) {
                    if (!_this.ignoreLintWarnings) {
                        compilation.warnings.push(formatted);
                    }
                }
                else {
                    compilation.errors.push(formatted);
                }
            });
            callback();
        };
    };
    ForkTsCheckerWebpackPlugin.prototype.createNoopEmitCallback = function () {
        // this function is empty intentionally
        // eslint-disable-next-line @typescript-eslint/no-empty-function
        return function noopEmitCallback() { };
    };
    ForkTsCheckerWebpackPlugin.prototype.printLoggerMessage = function (issue, formattedIssue) {
        if (issue.severity === issue_1.IssueSeverity.WARNING) {
            if (this.ignoreLintWarnings) {
                return;
            }
            this.logger.warn(formattedIssue);
        }
        else {
            this.logger.error(formattedIssue);
        }
    };
    ForkTsCheckerWebpackPlugin.prototype.createDoneCallback = function () {
        return function doneCallback() {
            var _this = this;
            if (!this.elapsed) {
                throw new Error('Execution order error');
            }
            var elapsed = Math.round(this.elapsed[0] * 1e9 + this.elapsed[1]);
            if (this.compiler) {
                var forkTsCheckerHooks = ForkTsCheckerWebpackPlugin.getCompilerHooks(this.compiler);
                forkTsCheckerHooks.done.call(this.diagnostics, this.lints, elapsed);
            }
            if (!this.silent && this.logger) {
                if (this.diagnostics.length || this.lints.length) {
                    (this.lints || []).concat(this.diagnostics).forEach(function (diagnostic) {
                        var formattedDiagnostic = _this.formatter(diagnostic);
                        _this.printLoggerMessage(diagnostic, formattedDiagnostic);
                    });
                }
                if (!this.diagnostics.length) {
                    this.logger.info(chalk_1.default.green('No type errors found'));
                }
                this.logger.info('Version: typescript ' +
                    chalk_1.default.bold(this.typescriptVersion) +
                    (this.eslint
                        ? ', eslint ' + chalk_1.default.bold(this.eslintVersion)
                        : ''));
                this.logger.info("Time: " + chalk_1.default.bold(Math.round(elapsed / 1e6).toString()) + " ms");
            }
        };
    };
    ForkTsCheckerWebpackPlugin.DEFAULT_MEMORY_LIMIT = 2048;
    return ForkTsCheckerWebpackPlugin;
}());
module.exports = ForkTsCheckerWebpackPlugin;
//# sourceMappingURL=index.js.map