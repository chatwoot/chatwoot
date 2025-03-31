"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadNewest = exports.requireFromCwd = exports.requireFromLinter = exports.getRequireFromCwd = exports.getRequireFromLinter = exports.createRequire = void 0;
const path_1 = __importDefault(require("path"));
const semver_1 = require("semver");
function createRequire(filename) {
    const Module = require("module");
    const fn = Module.createRequire ||
        Module.createRequireFromPath ||
        ((filename2) => {
            const mod = new Module(filename2);
            mod.filename = filename2;
            mod.paths = Module._nodeModulePaths(path_1.default.dirname(filename2));
            mod._compile("module.exports = require;", filename2);
            return mod.exports;
        });
    return fn(filename);
}
exports.createRequire = createRequire;
function isLinterPath(p) {
    return (p.includes(`eslint${path_1.default.sep}lib${path_1.default.sep}linter${path_1.default.sep}linter.js`) ||
        p.includes(`eslint${path_1.default.sep}lib${path_1.default.sep}linter.js`));
}
function getRequireFromLinter() {
    const linterPath = Object.keys(require.cache).find(isLinterPath);
    if (linterPath) {
        try {
            return createRequire(linterPath);
        }
        catch (_a) {
        }
    }
    return null;
}
exports.getRequireFromLinter = getRequireFromLinter;
function getRequireFromCwd() {
    try {
        const cwd = process.cwd();
        const relativeTo = path_1.default.join(cwd, "__placeholder__.js");
        return createRequire(relativeTo);
    }
    catch (_a) {
    }
    return null;
}
exports.getRequireFromCwd = getRequireFromCwd;
function requireFromLinter(module) {
    var _a;
    try {
        return (_a = getRequireFromLinter()) === null || _a === void 0 ? void 0 : _a(module);
    }
    catch (_b) {
    }
    return null;
}
exports.requireFromLinter = requireFromLinter;
function requireFromCwd(module) {
    var _a;
    try {
        return (_a = getRequireFromCwd()) === null || _a === void 0 ? void 0 : _a(module);
    }
    catch (_b) {
    }
    return null;
}
exports.requireFromCwd = requireFromCwd;
function loadNewest(items) {
    let target = null;
    for (const item of items) {
        const pkg = item.getPkg();
        if (pkg != null && (!target || (0, semver_1.lte)(target.version, pkg.version))) {
            target = { version: pkg.version, get: item.get };
        }
    }
    return target.get();
}
exports.loadNewest = loadNewest;
