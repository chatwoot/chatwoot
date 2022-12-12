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
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
var fs = __importStar(require("fs"));
var path = __importStar(require("path"));
var FilesRegister_1 = require("./FilesRegister");
var resolution_1 = require("./resolution");
var VueProgram_1 = require("./VueProgram");
var issue_1 = require("./issue");
var IncrementalChecker = /** @class */ (function () {
    function IncrementalChecker(_a) {
        var typescript = _a.typescript, programConfigFile = _a.programConfigFile, compilerOptions = _a.compilerOptions, eslinter = _a.eslinter, vue = _a.vue, _b = _a.checkSyntacticErrors, checkSyntacticErrors = _b === void 0 ? false : _b, resolveModuleName = _a.resolveModuleName, resolveTypeReferenceDirective = _a.resolveTypeReferenceDirective;
        this.files = new FilesRegister_1.FilesRegister(function () { return ({
            // data shape
            source: undefined,
            linted: false,
            eslints: []
        }); });
        this.typescript = typescript;
        this.programConfigFile = programConfigFile;
        this.compilerOptions = compilerOptions;
        this.eslinter = eslinter;
        this.vue = vue;
        this.checkSyntacticErrors = checkSyntacticErrors;
        this.resolveModuleName = resolveModuleName;
        this.resolveTypeReferenceDirective = resolveTypeReferenceDirective;
    }
    IncrementalChecker.loadProgramConfig = function (typescript, configFile, compilerOptions) {
        var tsconfig = typescript.readConfigFile(configFile, typescript.sys.readFile).config;
        tsconfig.compilerOptions = tsconfig.compilerOptions || {};
        tsconfig.compilerOptions = __assign({}, tsconfig.compilerOptions, compilerOptions);
        var parsed = typescript.parseJsonConfigFileContent(tsconfig, typescript.sys, path.dirname(configFile));
        return parsed;
    };
    IncrementalChecker.createProgram = function (typescript, programConfig, files, oldProgram, userResolveModuleName, userResolveTypeReferenceDirective) {
        var host = typescript.createCompilerHost(programConfig.options);
        var realGetSourceFile = host.getSourceFile;
        var _a = resolution_1.makeResolutionFunctions(userResolveModuleName, userResolveTypeReferenceDirective), resolveModuleName = _a.resolveModuleName, resolveTypeReferenceDirective = _a.resolveTypeReferenceDirective;
        host.resolveModuleNames = function (moduleNames, containingFile) {
            return moduleNames.map(function (moduleName) {
                return resolveModuleName(typescript, moduleName, containingFile, programConfig.options, host).resolvedModule;
            });
        };
        host.resolveTypeReferenceDirectives = function (typeDirectiveNames, containingFile) {
            return typeDirectiveNames.map(function (typeDirectiveName) {
                return resolveTypeReferenceDirective(typescript, typeDirectiveName, containingFile, programConfig.options, host).resolvedTypeReferenceDirective;
            });
        };
        host.getSourceFile = function (filePath, languageVersion, onError) {
            try {
                var stats = fs.statSync(filePath);
                files.setMtime(filePath, stats.mtime.valueOf());
            }
            catch (e) {
                // probably file does not exists
                files.remove(filePath);
            }
            // get source file only if there is no source in files register
            if (!files.has(filePath) || !files.getData(filePath).source) {
                files.mutateData(filePath, function (data) {
                    data.source = realGetSourceFile(filePath, languageVersion, onError);
                });
            }
            return files.getData(filePath).source;
        };
        return typescript.createProgram(programConfig.fileNames, programConfig.options, host, oldProgram // re-use old program
        );
    };
    IncrementalChecker.prototype.hasEsLinter = function () {
        return this.eslinter !== undefined;
    };
    IncrementalChecker.isFileExcluded = function (filePath) {
        return filePath.endsWith('.d.ts');
    };
    IncrementalChecker.prototype.nextIteration = function () {
        this.program = this.vue.enabled
            ? this.loadVueProgram(this.vue)
            : this.loadDefaultProgram();
    };
    IncrementalChecker.prototype.loadVueProgram = function (vueOptions) {
        this.programConfig =
            this.programConfig ||
                VueProgram_1.VueProgram.loadProgramConfig(this.typescript, this.programConfigFile, this.compilerOptions);
        return VueProgram_1.VueProgram.createProgram(this.typescript, this.programConfig, path.dirname(this.programConfigFile), this.files, this.program, this.resolveModuleName, this.resolveTypeReferenceDirective, vueOptions);
    };
    IncrementalChecker.prototype.loadDefaultProgram = function () {
        this.programConfig =
            this.programConfig ||
                IncrementalChecker.loadProgramConfig(this.typescript, this.programConfigFile, this.compilerOptions);
        return IncrementalChecker.createProgram(this.typescript, this.programConfig, this.files, this.program, this.resolveModuleName, this.resolveTypeReferenceDirective);
    };
    IncrementalChecker.prototype.getTypeScriptIssues = function (cancellationToken) {
        return __awaiter(this, void 0, void 0, function () {
            var program, tsDiagnostics, filesToCheck;
            var _this = this;
            return __generator(this, function (_a) {
                program = this.program;
                if (!program) {
                    throw new Error('Invoked called before program initialized');
                }
                tsDiagnostics = [];
                filesToCheck = program.getSourceFiles();
                filesToCheck.forEach(function (sourceFile) {
                    if (cancellationToken) {
                        cancellationToken.throwIfCancellationRequested();
                    }
                    var tsDiagnosticsToRegister = _this
                        .checkSyntacticErrors
                        ? program
                            .getSemanticDiagnostics(sourceFile, cancellationToken)
                            .concat(program.getSyntacticDiagnostics(sourceFile, cancellationToken))
                        : program.getSemanticDiagnostics(sourceFile, cancellationToken);
                    tsDiagnostics.push.apply(tsDiagnostics, tsDiagnosticsToRegister);
                });
                return [2 /*return*/, issue_1.createIssuesFromTsDiagnostics(tsDiagnostics, this.typescript)];
            });
        });
    };
    IncrementalChecker.prototype.getEsLintIssues = function (cancellationToken) {
        return __awaiter(this, void 0, void 0, function () {
            var filesToLint, currentEsLintErrors, reports;
            var _this = this;
            return __generator(this, function (_a) {
                filesToLint = this.files
                    .keys()
                    .filter(function (filePath) {
                    return !_this.files.getData(filePath).linted &&
                        !IncrementalChecker.isFileExcluded(filePath);
                });
                currentEsLintErrors = new Map();
                filesToLint.forEach(function (fileName) {
                    cancellationToken.throwIfCancellationRequested();
                    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
                    var report = _this.eslinter.getReport(fileName);
                    if (report !== undefined) {
                        currentEsLintErrors.set(fileName, report);
                    }
                });
                // set lints in files register
                currentEsLintErrors.forEach(function (lint, filePath) {
                    _this.files.mutateData(filePath, function (data) {
                        data.linted = true;
                        data.eslints.push(lint);
                    });
                });
                // set all files as linted
                this.files.keys().forEach(function (filePath) {
                    _this.files.mutateData(filePath, function (data) {
                        data.linted = true;
                    });
                });
                reports = this.files
                    .keys()
                    .reduce(function (innerLints, filePath) {
                    return innerLints.concat(_this.files.getData(filePath).eslints);
                }, []);
                return [2 /*return*/, issue_1.createIssuesFromEsLintReports(reports)];
            });
        });
    };
    return IncrementalChecker;
}());
exports.IncrementalChecker = IncrementalChecker;
//# sourceMappingURL=IncrementalChecker.js.map