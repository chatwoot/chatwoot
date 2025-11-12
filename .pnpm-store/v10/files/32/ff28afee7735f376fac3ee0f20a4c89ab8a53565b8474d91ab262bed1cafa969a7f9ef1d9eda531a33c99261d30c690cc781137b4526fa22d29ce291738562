"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.findFlatConfigFile = exports.shouldUseFlatConfig = void 0;
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
const FLAT_CONFIG_FILENAMES = [
    'eslint.config.js',
    'eslint.config.mjs',
    'eslint.config.cjs'
];
function shouldUseFlatConfig(cwd) {
    switch (process.env.ESLINT_USE_FLAT_CONFIG) {
        case 'true':
            return true;
        case 'false':
            return false;
        default:
            return Boolean(findFlatConfigFile(cwd));
    }
}
exports.shouldUseFlatConfig = shouldUseFlatConfig;
function findFlatConfigFile(cwd) {
    return findUp(FLAT_CONFIG_FILENAMES, { cwd });
}
exports.findFlatConfigFile = findFlatConfigFile;
function findUp(names, options) {
    let directory = path_1.default.resolve(options.cwd);
    const { root } = path_1.default.parse(directory);
    const stopAt = path_1.default.resolve(directory, root);
    while (true) {
        for (const name of names) {
            const target = path_1.default.resolve(directory, name);
            const stat = fs_1.default.existsSync(target)
                ? fs_1.default.statSync(target, {
                    throwIfNoEntry: false
                })
                : null;
            if (stat === null || stat === void 0 ? void 0 : stat.isFile()) {
                return target;
            }
        }
        if (directory === stopAt) {
            break;
        }
        directory = path_1.default.dirname(directory);
    }
    return null;
}
