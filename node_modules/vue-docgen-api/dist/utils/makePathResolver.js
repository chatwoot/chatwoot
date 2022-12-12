"use strict";
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var resolveAliases_1 = __importDefault(require("../utils/resolveAliases"));
var resolvePathFrom_1 = __importDefault(require("../utils/resolvePathFrom"));
function makePathResolver(refDirName, aliases, modules) {
    return function (filePath, originalDirNameOverride) {
        return (0, resolvePathFrom_1.default)((0, resolveAliases_1.default)(filePath, aliases || {}, refDirName), __spreadArray([
            originalDirNameOverride || refDirName
        ], (modules || []), true));
    };
}
exports.default = makePathResolver;
