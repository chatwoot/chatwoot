"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
var path_1 = require("path");
var missing_files_cache_1 = __importDefault(require("./missing-files-cache"));
var SUFFIXES = ['', '.js', '.ts', '.vue', '.jsx', '.tsx'];
function resolvePathFrom(path, from) {
    var finalPath = null;
    SUFFIXES.forEach(function (s) {
        if (!finalPath) {
            try {
                finalPath = require.resolve("".concat(path).concat(s), {
                    paths: from
                });
            }
            catch (e) {
                // eat the error
            }
        }
        if (!finalPath) {
            try {
                finalPath = require.resolve((0, path_1.join)(path, "index".concat(s)), {
                    paths: from
                });
            }
            catch (e) {
                // eat the error
            }
        }
        if (!finalPath) {
            for (var i = 0; i < from.length; i++) {
                try {
                    finalPath = require.resolve((0, path_1.join)(from[i], "".concat(path).concat(s)));
                    if (finalPath.length) {
                        break;
                    }
                }
                catch (e) {
                    // eat the error
                }
            }
        }
    });
    try {
        var packagePath = require.resolve((0, path_1.join)(path, 'package.json'), {
            paths: from
        });
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        var pkg = require(packagePath);
        // if it is an es6 module use the module instead of commonjs
        finalPath = require.resolve((0, path_1.join)(path, pkg.module || pkg.main));
    }
    catch (e) {
        // eat the error
    }
    if (!finalPath) {
        if (!missing_files_cache_1.default[path]) {
            // eslint-disable-next-line no-console
            console.warn("Neither '".concat(path, ".vue' nor '").concat(path, ".js(x)' or '").concat(path, "/index.js(x)' or '").concat(path, "/index.ts(x)' could be found in '").concat(from, "'"));
            missing_files_cache_1.default[path] = true;
        }
    }
    return finalPath;
}
exports.default = resolvePathFrom;
