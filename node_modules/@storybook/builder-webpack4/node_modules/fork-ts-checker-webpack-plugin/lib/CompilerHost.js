"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
var LinkedList_1 = require("./LinkedList");
var VueProgram_1 = require("./VueProgram");
var CompilerHost = /** @class */ (function () {
    function CompilerHost(typescript, vueOptions, programConfigFile, compilerOptions, checkSyntacticErrors, userResolveModuleName, userResolveTypeReferenceDirective) {
        var _this = this;
        this.typescript = typescript;
        this.vueOptions = vueOptions;
        // intercept all watch events and collect them until we get notification to start compilation
        this.directoryWatchers = new LinkedList_1.LinkedList();
        this.fileWatchers = new LinkedList_1.LinkedList();
        this.knownFiles = new Set();
        this.gatheredDiagnostic = [];
        this.afterCompile = function () {
            /* do nothing */
        };
        this.compilationStarted = false;
        this.createProgram = this.typescript
            .createEmitAndSemanticDiagnosticsBuilderProgram;
        this.tsHost = typescript.createWatchCompilerHost(programConfigFile, compilerOptions, typescript.sys, typescript.createEmitAndSemanticDiagnosticsBuilderProgram, function (diag) {
            if (!checkSyntacticErrors &&
                diag.code >= 1000 &&
                diag.code < 2000 &&
                diag.file // if diag.file is undefined, this is not a syntactic error, but a global error that should be emitted
            ) {
                return;
            }
            _this.gatheredDiagnostic.push(diag);
        }, function () {
            // do nothing
        });
        this.configFileName = this.tsHost.configFileName;
        this.optionsToExtend = this.tsHost.optionsToExtend || {};
        if (userResolveModuleName) {
            this.resolveModuleNames = function (moduleNames, containingFile) {
                return moduleNames.map(function (moduleName) {
                    return userResolveModuleName(_this.typescript, moduleName, containingFile, _this.optionsToExtend, _this).resolvedModule;
                });
            };
        }
        if (userResolveTypeReferenceDirective) {
            this.resolveTypeReferenceDirectives = function (typeDirectiveNames, containingFile) {
                return typeDirectiveNames.map(function (typeDirectiveName) {
                    return userResolveTypeReferenceDirective(_this.typescript, typeDirectiveName, containingFile, _this.optionsToExtend, _this).resolvedTypeReferenceDirective;
                });
            };
        }
    }
    CompilerHost.prototype.getProgram = function () {
        if (!this.program) {
            throw new Error('Program is not created yet.');
        }
        return this.program.getProgram().getProgram();
    };
    CompilerHost.prototype.getAllKnownFiles = function () {
        return this.knownFiles;
    };
    CompilerHost.prototype.processChanges = function () {
        return __awaiter(this, void 0, void 0, function () {
            var initialCompile, errors, previousDiagnostic, resultPromise, files, updatedFiles, removedFiles, results;
            var _this = this;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0:
                        if (!!this.lastProcessing) return [3 /*break*/, 2];
                        initialCompile = new Promise(function (resolve) {
                            _this.afterCompile = function () {
                                resolve(_this.gatheredDiagnostic);
                                _this.afterCompile = function () {
                                    /* do nothing */
                                };
                                _this.compilationStarted = false;
                            };
                        });
                        this.lastProcessing = initialCompile;
                        this.program = this.typescript.createWatchProgram(this);
                        return [4 /*yield*/, initialCompile];
                    case 1:
                        errors = _a.sent();
                        return [2 /*return*/, {
                                results: errors,
                                updatedFiles: Array.from(this.knownFiles),
                                removedFiles: []
                            }];
                    case 2: 
                    // since we do not have a way to pass cancellation token to typescript,
                    // we just wait until previous compilation finishes.
                    return [4 /*yield*/, this.lastProcessing];
                    case 3:
                        // since we do not have a way to pass cancellation token to typescript,
                        // we just wait until previous compilation finishes.
                        _a.sent();
                        previousDiagnostic = this.gatheredDiagnostic;
                        this.gatheredDiagnostic = [];
                        resultPromise = new Promise(function (resolve) {
                            _this.afterCompile = function () {
                                resolve(_this.gatheredDiagnostic);
                                _this.afterCompile = function () {
                                    /* do nothing */
                                };
                                _this.compilationStarted = false;
                            };
                        });
                        this.lastProcessing = resultPromise;
                        files = [];
                        this.directoryWatchers.forEach(function (item) {
                            for (var _i = 0, _a = item.events; _i < _a.length; _i++) {
                                var e = _a[_i];
                                item.callback(e.fileName);
                            }
                            item.events.length = 0;
                        });
                        updatedFiles = [];
                        removedFiles = [];
                        this.fileWatchers.forEach(function (item) {
                            for (var _i = 0, _a = item.events; _i < _a.length; _i++) {
                                var e = _a[_i];
                                item.callback(e.fileName, e.eventKind);
                                files.push(e.fileName);
                                if (e.eventKind === _this.typescript.FileWatcherEventKind.Created ||
                                    e.eventKind === _this.typescript.FileWatcherEventKind.Changed) {
                                    updatedFiles.push(e.fileName);
                                }
                                else if (e.eventKind === _this.typescript.FileWatcherEventKind.Deleted) {
                                    removedFiles.push(e.fileName);
                                }
                            }
                            item.events.length = 0;
                        });
                        // if the files are not relevant to typescript it may choose not to compile
                        // in this case we need to trigger promise resolution from here
                        if (!this.compilationStarted) {
                            // keep diagnostic from previous run
                            this.gatheredDiagnostic = previousDiagnostic;
                            this.afterCompile();
                            return [2 /*return*/, {
                                    results: this.gatheredDiagnostic,
                                    updatedFiles: [],
                                    removedFiles: []
                                }];
                        }
                        return [4 /*yield*/, resultPromise];
                    case 4:
                        results = _a.sent();
                        return [2 /*return*/, { results: results, updatedFiles: updatedFiles, removedFiles: removedFiles }];
                }
            });
        });
    };
    CompilerHost.prototype.setTimeout = function (
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    callback, ms) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        var args = [];
        for (
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        var _i = 2; 
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        _i < arguments.length; 
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        _i++) {
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            args[_i - 2] = arguments[_i];
        }
        // There are 2 things we are hacking here:
        // 1. This method only called from watch program to wait until all files
        // are written to filesystem (for example, when doing 'save all')
        // We are intercepting all change notifications, and letting
        // them through only when webpack starts processing changes.
        // Therefore, at this point normally files are already all saved,
        // so we do not need to waste another 250 ms (hardcoded in TypeScript).
        // On the other hand there may be occasional glitch, when our incremental
        // compiler will receive the notification too late, and process it when
        // next compilation would start.
        // 2. It seems to be only reliable way to intercept a moment when TypeScript
        // actually starts compilation.
        //
        // Ideally we probably should not let TypeScript call all those watching
        // methods by itself, and instead forward changes from webpack.
        // Unfortunately, at the moment TypeScript incremental API is quite
        // immature (for example, minor changes in how you use it cause
        // dramatic compilation time increase), so we have to stick with these
        // hacks for now.
        this.compilationStarted = true;
        return (this.typescript.sys.setTimeout || setTimeout)(callback, 1, args);
    };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    CompilerHost.prototype.clearTimeout = function (timeoutId) {
        (this.typescript.sys.clearTimeout || clearTimeout)(timeoutId);
    };
    CompilerHost.prototype.onWatchStatusChange = function () {
        // do nothing
    };
    CompilerHost.prototype.watchDirectory = function (path, callback, recursive) {
        var slot = { callback: callback, events: [] };
        var node = this.directoryWatchers.add(slot);
        this.tsHost.watchDirectory(path, function (fileName) {
            slot.events.push({ fileName: fileName });
        }, recursive);
        return {
            close: function () {
                node.detachSelf();
            }
        };
    };
    CompilerHost.prototype.watchFile = function (path, callback, pollingInterval) {
        var _this = this;
        var slot = { callback: callback, events: [] };
        var node = this.fileWatchers.add(slot);
        this.knownFiles.add(path);
        this.tsHost.watchFile(path, function (fileName, eventKind) {
            if (eventKind === _this.typescript.FileWatcherEventKind.Created) {
                _this.knownFiles.add(fileName);
            }
            else if (eventKind === _this.typescript.FileWatcherEventKind.Deleted) {
                _this.knownFiles.delete(fileName);
            }
            slot.events.push({ fileName: fileName, eventKind: eventKind });
        }, pollingInterval);
        return {
            close: function () {
                node.detachSelf();
            }
        };
    };
    CompilerHost.prototype.fileExists = function (path) {
        return this.tsHost.fileExists(path);
    };
    CompilerHost.prototype.readFile = function (path, encoding) {
        var content = this.tsHost.readFile(path, encoding);
        // get typescript contents from Vue file
        if (content && VueProgram_1.VueProgram.isVue(path)) {
            var resolved = VueProgram_1.VueProgram.resolveScriptBlock(this.typescript, content, this.vueOptions.compiler);
            return resolved.content;
        }
        return content;
    };
    CompilerHost.prototype.directoryExists = function (path) {
        return ((this.tsHost.directoryExists && this.tsHost.directoryExists(path)) ||
            false);
    };
    CompilerHost.prototype.getDirectories = function (path) {
        return ((this.tsHost.getDirectories && this.tsHost.getDirectories(path)) || []);
    };
    CompilerHost.prototype.readDirectory = function (path, extensions, exclude, include, depth) {
        return this.typescript.sys.readDirectory(path, extensions, exclude, include, depth);
    };
    CompilerHost.prototype.getCurrentDirectory = function () {
        return this.tsHost.getCurrentDirectory();
    };
    CompilerHost.prototype.getDefaultLibFileName = function (options) {
        return this.tsHost.getDefaultLibFileName(options);
    };
    CompilerHost.prototype.getEnvironmentVariable = function (name) {
        return (this.tsHost.getEnvironmentVariable &&
            this.tsHost.getEnvironmentVariable(name));
    };
    CompilerHost.prototype.getNewLine = function () {
        return this.tsHost.getNewLine();
    };
    CompilerHost.prototype.realpath = function (path) {
        if (!this.tsHost.realpath) {
            throw new Error('The realpath function is not supported by the CompilerHost.');
        }
        return this.tsHost.realpath(path);
    };
    CompilerHost.prototype.trace = function (s) {
        if (this.tsHost.trace) {
            this.tsHost.trace(s);
        }
    };
    CompilerHost.prototype.useCaseSensitiveFileNames = function () {
        return this.tsHost.useCaseSensitiveFileNames();
    };
    CompilerHost.prototype.onUnRecoverableConfigFileDiagnostic = function () {
        // do nothing
    };
    CompilerHost.prototype.afterProgramCreate = function (program) {
        // all actual diagnostics happens here
        if (this.tsHost.afterProgramCreate) {
            this.tsHost.afterProgramCreate(program);
        }
        this.afterCompile();
    };
    // the functions below are use internally by typescript. we cannot use non-emitting version of incremental watching API
    // because it is
    // - much slower for some reason,
    // - writes files anyway (o_O)
    // - has different way of providing diagnostics. (with this version we can at least reliably get it from afterProgramCreate)
    CompilerHost.prototype.createDirectory = function () {
        // pretend everything was ok
    };
    CompilerHost.prototype.writeFile = function () {
        // pretend everything was ok
    };
    CompilerHost.prototype.onCachedDirectoryStructureHostCreate = function () {
        // pretend everything was ok
    };
    return CompilerHost;
}());
exports.CompilerHost = CompilerHost;
//# sourceMappingURL=CompilerHost.js.map