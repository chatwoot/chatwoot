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
Object.defineProperty(exports, "__esModule", { value: true });
var path = __importStar(require("path"));
var fs = __importStar(require("fs"));
function resolveAliases(filePath, aliases, refDirName) {
    if (refDirName === void 0) { refDirName = ''; }
    var aliasKeys = Object.keys(aliases);
    var aliasResolved = null;
    if (!aliasKeys.length) {
        return filePath;
    }
    for (var _i = 0, aliasKeys_1 = aliasKeys; _i < aliasKeys_1.length; _i++) {
        var aliasKey = aliasKeys_1[_i];
        var aliasValueWithSlash = aliasKey + '/';
        var aliasMatch = filePath.substring(0, aliasValueWithSlash.length) === aliasValueWithSlash;
        var aliasValue = aliases[aliasKey];
        if (!aliasMatch) {
            continue;
        }
        if (!Array.isArray(aliasValue)) {
            aliasResolved = path.join(aliasValue, filePath.substring(aliasKey.length + 1));
            continue;
        }
        for (var _a = 0, aliasValue_1 = aliasValue; _a < aliasValue_1.length; _a++) {
            var alias = aliasValue_1[_a];
            var absolutePath = path.resolve(refDirName, alias, filePath.substring(aliasKey.length + 1));
            if (fs.existsSync(absolutePath)) {
                aliasResolved = absolutePath;
                break;
            }
        }
    }
    return aliasResolved === null ?
        filePath :
        aliasResolved;
}
exports.default = resolveAliases;
