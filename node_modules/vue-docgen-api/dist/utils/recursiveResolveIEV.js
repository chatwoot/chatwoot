"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
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
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.resolveIEV = void 0;
var fs_1 = require("fs");
var path = __importStar(require("path"));
var util_1 = require("util");
var recast_1 = require("recast");
var ts_map_1 = __importDefault(require("ts-map"));
var babel_parser_1 = __importDefault(require("../babel-parser"));
var cacher_1 = __importDefault(require("./cacher"));
var resolveImmediatelyExported_1 = __importDefault(require("./resolveImmediatelyExported"));
var read = (0, util_1.promisify)(fs_1.readFile);
// eslint-disable-next-line @typescript-eslint/no-var-requires
var hash = require('hash-sum');
/**
 * Recursively resolves specified variables to their actual files
 * Useful when using intermeriary files like this
 *
 * ```js
 * export mixin from "path/to/mixin"
 * ```
 *
 * @param pathResolver function to resolve relative to absolute path
 * @param varToFilePath set of variables to be resolved (will be mutated into the final mapping)
 */
function recursiveResolveIEV(pathResolver, varToFilePath, validExtends) {
    return __awaiter(this, void 0, void 0, function () {
        var hashBefore;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    hashBefore = hash(varToFilePath);
                    // in this case I need to resolve IEV in sequence in case they are defined multiple times
                    // eslint-disable-next-line no-await-in-loop
                    return [4 /*yield*/, resolveIEV(pathResolver, varToFilePath, validExtends)];
                case 1:
                    // in this case I need to resolve IEV in sequence in case they are defined multiple times
                    // eslint-disable-next-line no-await-in-loop
                    _a.sent();
                    _a.label = 2;
                case 2:
                    if (hashBefore !== hash(varToFilePath)) return [3 /*break*/, 0];
                    _a.label = 3;
                case 3: return [2 /*return*/];
            }
        });
    });
}
exports.default = recursiveResolveIEV;
/**
 * Resolves specified variables to their actual files
 * Useful when using intermeriary files like this
 *
 * ```js
 * export mixin from "path/to/mixin"
 * ```
 *
 * @param pathResolver function to resolve relative to absolute path
 * @param varToFilePath set of variables to be resolved (will be mutated into the final mapping)
 */
function resolveIEV(pathResolver, varToFilePath, validExtends) {
    return __awaiter(this, void 0, void 0, function () {
        var filePathToVars;
        var _this = this;
        return __generator(this, function (_a) {
            switch (_a.label) {
                case 0:
                    filePathToVars = new ts_map_1.default();
                    Object.keys(varToFilePath).forEach(function (k) {
                        var exportedVariable = varToFilePath[k];
                        exportedVariable.filePath.forEach(function (filePath) {
                            var exportToLocalMap = filePathToVars.get(filePath) || new ts_map_1.default();
                            exportToLocalMap.set(k, exportedVariable.exportName);
                            filePathToVars.set(filePath, exportToLocalMap);
                        });
                    });
                    // then roll though this map and replace varToFilePath elements with their final destinations
                    // {
                    //	nameOfVariable:{filePath:['filesWhereToFindIt'], exportedName:'nameUsedInExportThatCanBeUsedForFiltering'}
                    // }
                    return [4 /*yield*/, Promise.all(filePathToVars.entries().map(function (_a) {
                            var filePath = _a[0], exportToLocal = _a[1];
                            return __awaiter(_this, void 0, void 0, function () {
                                var exportedVariableNames_1, fullFilePath_1, source_1, astRemote, returnedVariables_1, e_1;
                                return __generator(this, function (_b) {
                                    switch (_b.label) {
                                        case 0:
                                            if (!(filePath && exportToLocal)) return [3 /*break*/, 4];
                                            exportedVariableNames_1 = [];
                                            exportToLocal.forEach(function (exportedName) {
                                                if (exportedName) {
                                                    exportedVariableNames_1.push(exportedName);
                                                }
                                            });
                                            _b.label = 1;
                                        case 1:
                                            _b.trys.push([1, 3, , 4]);
                                            fullFilePath_1 = pathResolver(filePath);
                                            if (!fullFilePath_1 || !validExtends(fullFilePath_1)) {
                                                return [2 /*return*/];
                                            }
                                            return [4 /*yield*/, read(fullFilePath_1, {
                                                    encoding: 'utf-8'
                                                })];
                                        case 2:
                                            source_1 = _b.sent();
                                            astRemote = (0, cacher_1.default)(function () { return (0, recast_1.parse)(source_1, { parser: (0, babel_parser_1.default)() }); }, source_1);
                                            returnedVariables_1 = (0, resolveImmediatelyExported_1.default)(astRemote, exportedVariableNames_1);
                                            if (Object.keys(returnedVariables_1).length) {
                                                exportToLocal.forEach(function (exported, local) {
                                                    if (exported && local) {
                                                        var aliasedVariable = returnedVariables_1[exported];
                                                        if (aliasedVariable) {
                                                            aliasedVariable.filePath = aliasedVariable.filePath
                                                                .map(function (p) { return pathResolver(p, path.dirname(fullFilePath_1)); })
                                                                .filter(function (a) { return a; });
                                                            varToFilePath[local] = aliasedVariable;
                                                        }
                                                    }
                                                });
                                            }
                                            return [3 /*break*/, 4];
                                        case 3:
                                            e_1 = _b.sent();
                                            return [3 /*break*/, 4];
                                        case 4: return [2 /*return*/];
                                    }
                                });
                            });
                        }))];
                case 1:
                    // then roll though this map and replace varToFilePath elements with their final destinations
                    // {
                    //	nameOfVariable:{filePath:['filesWhereToFindIt'], exportedName:'nameUsedInExportThatCanBeUsedForFiltering'}
                    // }
                    _a.sent();
                    return [2 /*return*/];
            }
        });
    });
}
exports.resolveIEV = resolveIEV;
