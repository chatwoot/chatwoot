"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAcorn = void 0;
const module_1 = require("module");
const require_utils_1 = require("./require-utils");
let acornCache;
function getAcorn() {
    if (!acornCache) {
        acornCache = (0, require_utils_1.loadNewest)([
            {
                getPkg() {
                    return (0, require_utils_1.requireFromCwd)("acorn/package.json");
                },
                get() {
                    return (0, require_utils_1.requireFromCwd)("acorn");
                },
            },
            {
                getPkg() {
                    return requireFromEspree("acorn/package.json");
                },
                get() {
                    return requireFromEspree("acorn");
                },
            },
            {
                getPkg() {
                    return require("acorn/package.json");
                },
                get() {
                    return require("acorn");
                },
            },
        ]);
    }
    return acornCache;
}
exports.getAcorn = getAcorn;
function requireFromEspree(module) {
    try {
        return (0, module_1.createRequire)(getEspreePath())(module);
    }
    catch (_a) {
    }
    return null;
}
function getEspreePath() {
    return (0, require_utils_1.loadNewest)([
        {
            getPkg() {
                return (0, require_utils_1.requireFromCwd)("espree/package.json");
            },
            get() {
                return (0, require_utils_1.getRequireFromCwd)().resolve("espree");
            },
        },
        {
            getPkg() {
                return (0, require_utils_1.requireFromLinter)("espree/package.json");
            },
            get() {
                return (0, require_utils_1.getRequireFromLinter)().resolve("espree");
            },
        },
        {
            getPkg() {
                return require("espree/package.json");
            },
            get() {
                return require.resolve("espree");
            },
        },
    ]);
}
