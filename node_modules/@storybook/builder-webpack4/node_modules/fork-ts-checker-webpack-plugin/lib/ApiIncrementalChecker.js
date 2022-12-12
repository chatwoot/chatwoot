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
var CompilerHost_1 = require("./CompilerHost");
var issue_1 = require("./issue");
var ApiIncrementalChecker = /** @class */ (function () {
    function ApiIncrementalChecker(_a) {
        var typescript = _a.typescript, programConfigFile = _a.programConfigFile, compilerOptions = _a.compilerOptions, eslinter = _a.eslinter, vue = _a.vue, _b = _a.checkSyntacticErrors, checkSyntacticErrors = _b === void 0 ? false : _b, resolveModuleName = _a.resolveModuleName, resolveTypeReferenceDirective = _a.resolveTypeReferenceDirective;
        this.currentEsLintErrors = new Map();
        this.lastUpdatedFiles = [];
        this.lastRemovedFiles = [];
        this.eslinter = eslinter;
        this.tsIncrementalCompiler = new CompilerHost_1.CompilerHost(typescript, vue, programConfigFile, compilerOptions, checkSyntacticErrors, resolveModuleName, resolveTypeReferenceDirective);
        this.typescript = typescript;
    }
    ApiIncrementalChecker.prototype.hasEsLinter = function () {
        return this.eslinter !== undefined;
    };
    ApiIncrementalChecker.prototype.isFileExcluded = function (filePath) {
        return filePath.endsWith('.d.ts');
    };
    ApiIncrementalChecker.prototype.nextIteration = function () {
        // do nothing
    };
    ApiIncrementalChecker.prototype.getTypeScriptIssues = function () {
        return __awaiter(this, void 0, void 0, function () {
            var tsDiagnostics;
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, this.tsIncrementalCompiler.processChanges()];
                    case 1:
                        tsDiagnostics = _a.sent();
                        this.lastUpdatedFiles = tsDiagnostics.updatedFiles;
                        this.lastRemovedFiles = tsDiagnostics.removedFiles;
                        return [2 /*return*/, issue_1.createIssuesFromTsDiagnostics(tsDiagnostics.results, this.typescript)];
                }
            });
        });
    };
    ApiIncrementalChecker.prototype.getEsLintIssues = function (cancellationToken) {
        return __awaiter(this, void 0, void 0, function () {
            var _i, _a, removedFile, _b, _c, updatedFile, report, reports;
            return __generator(this, function (_d) {
                if (!this.eslinter) {
                    throw new Error('EsLint is not enabled in the plugin.');
                }
                for (_i = 0, _a = this.lastRemovedFiles; _i < _a.length; _i++) {
                    removedFile = _a[_i];
                    this.currentEsLintErrors.delete(removedFile);
                }
                for (_b = 0, _c = this.lastUpdatedFiles; _b < _c.length; _b++) {
                    updatedFile = _c[_b];
                    cancellationToken.throwIfCancellationRequested();
                    if (this.isFileExcluded(updatedFile)) {
                        continue;
                    }
                    report = this.eslinter.getReport(updatedFile);
                    if (report !== undefined) {
                        this.currentEsLintErrors.set(updatedFile, report);
                    }
                    else if (this.currentEsLintErrors.has(updatedFile)) {
                        this.currentEsLintErrors.delete(updatedFile);
                    }
                }
                reports = Array.from(this.currentEsLintErrors.values());
                return [2 /*return*/, issue_1.createIssuesFromEsLintReports(reports)];
            });
        });
    };
    return ApiIncrementalChecker;
}());
exports.ApiIncrementalChecker = ApiIncrementalChecker;
//# sourceMappingURL=ApiIncrementalChecker.js.map