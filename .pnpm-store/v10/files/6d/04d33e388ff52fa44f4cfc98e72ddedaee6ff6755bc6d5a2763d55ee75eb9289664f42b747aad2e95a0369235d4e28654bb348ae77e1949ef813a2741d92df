"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getNewestEspreeKind = exports.getEspree = void 0;
const require_utils_1 = require("./require-utils");
const semver_1 = require("semver");
let espreeCache = null;
function getEspree() {
    if (!espreeCache) {
        espreeCache = (0, require_utils_1.loadNewest)([
            {
                getPkg() {
                    return (0, require_utils_1.requireFromCwd)("espree/package.json");
                },
                get() {
                    return (0, require_utils_1.requireFromCwd)("espree");
                },
            },
            {
                getPkg() {
                    return (0, require_utils_1.requireFromLinter)("espree/package.json");
                },
                get() {
                    return (0, require_utils_1.requireFromLinter)("espree");
                },
            },
            {
                getPkg() {
                    return require("espree/package.json");
                },
                get() {
                    return require("espree");
                },
            },
        ]);
    }
    return espreeCache;
}
exports.getEspree = getEspree;
let kindCache = null;
function getNewestEspreeKind() {
    if (kindCache) {
        return kindCache;
    }
    const cwdPkg = (0, require_utils_1.requireFromCwd)("espree/package.json");
    const linterPkg = (0, require_utils_1.requireFromLinter)("espree/package.json");
    const self = require("espree/package.json");
    let target = {
        kind: "self",
        version: self.version,
    };
    if (cwdPkg != null && (0, semver_1.lte)(target.version, cwdPkg.version)) {
        target = { kind: "cwd", version: cwdPkg.version };
    }
    if (linterPkg != null && (0, semver_1.lte)(target.version, linterPkg.version)) {
        target = { kind: "linter", version: linterPkg.version };
    }
    return (kindCache = target.kind);
}
exports.getNewestEspreeKind = getNewestEspreeKind;
