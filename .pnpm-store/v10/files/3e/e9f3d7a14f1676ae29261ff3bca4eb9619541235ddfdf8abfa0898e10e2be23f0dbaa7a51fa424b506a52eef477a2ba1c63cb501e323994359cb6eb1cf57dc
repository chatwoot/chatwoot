"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.IgnoredPaths = void 0;
const fs_1 = require("fs");
const path_1 = require("path");
const path_utils_1 = require("./path-utils");
const ignore_1 = __importDefault(require("ignore"));
const debug_1 = __importDefault(require("debug"));
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:ignored-paths');
const ESLINT_IGNORE_FILENAME = '.eslintignore';
const DEFAULT_IGNORE_DIRS = ['/node_modules/*', '/bower_components/*'];
const DEFAULT_OPTIONS = {
    dotfiles: false
};
function findFile(cwd, name) {
    const ignoreFilePath = (0, path_1.resolve)(cwd, name);
    return (0, fs_1.existsSync)(ignoreFilePath) && (0, fs_1.statSync)(ignoreFilePath).isFile()
        ? ignoreFilePath
        : '';
}
function findIgnoreFile(cwd) {
    return findFile(cwd, ESLINT_IGNORE_FILENAME);
}
function findPackageJSONFile(cwd) {
    return findFile(cwd, 'package.json');
}
function mergeDefaultOptions(options) {
    const mergedOptions = Object.assign({}, DEFAULT_OPTIONS, options);
    if (!mergedOptions.cwd) {
        mergedOptions.cwd = process.cwd();
    }
    debug('mergeDefaultOptions: mergedOptions = %j', mergedOptions);
    return mergedOptions;
}
const normalizePathSeps = path_1.sep === '/'
    ? (str) => str
    : ((seps, str) => str.replace(seps, '/')).bind(null, new RegExp(`\\${path_1.sep}`, 'g'));
function relativize(globPattern, relativePathToOldBaseDir) {
    if (relativePathToOldBaseDir === '') {
        return globPattern;
    }
    const prefix = globPattern.startsWith('!') ? '!' : '';
    const globWithoutPrefix = globPattern.replace(/^!/, '');
    if (globWithoutPrefix.startsWith('/')) {
        return `${prefix}/${normalizePathSeps(relativePathToOldBaseDir)}${globWithoutPrefix}`;
    }
    return globPattern;
}
class IgnoredPaths {
    constructor(providedOptions) {
        const options = mergeDefaultOptions(providedOptions);
        this.cache = {};
        this.defaultPatterns = [].concat(DEFAULT_IGNORE_DIRS, options.patterns || []);
        this.ignoreFileDir =
            options.ignore !== false && options.ignorePath
                ? (0, path_1.dirname)((0, path_1.resolve)(options.cwd, options.ignorePath))
                : options.cwd;
        this.options = options;
        this._baseDir = null;
        this.ig = {
            custom: (0, ignore_1.default)(),
            default: (0, ignore_1.default)()
        };
        this.defaultPatterns.forEach(pattern => this.addPatternRelativeToCwd(this.ig.default, pattern));
        if (options.dotfiles !== true) {
            this.addPatternRelativeToCwd(this.ig.default, '.*');
            this.addPatternRelativeToCwd(this.ig.default, '!../');
        }
        this.ig.custom.ignoreFiles = [];
        this.ig.default.ignoreFiles = [];
        if (options.ignore !== false) {
            let ignorePath;
            if (options.ignorePath) {
                debug('Using specific ignore file');
                try {
                    (0, fs_1.statSync)(options.ignorePath);
                    ignorePath = options.ignorePath;
                }
                catch (e) {
                    e.message = `Cannot read ignore file: ${options.ignorePath}\nError: ${e.message}`;
                    throw e;
                }
            }
            else {
                debug(`Looking for ignore file in ${options.cwd}`);
                ignorePath = findIgnoreFile(options.cwd);
                try {
                    (0, fs_1.statSync)(ignorePath);
                    debug(`Loaded ignore file ${ignorePath}`);
                }
                catch (e) {
                    debug('Could not find ignore file in cwd');
                }
            }
            if (ignorePath) {
                debug(`Adding ${ignorePath}`);
                this.addIgnoreFile(this.ig.custom, ignorePath);
                this.addIgnoreFile(this.ig.default, ignorePath);
            }
            else {
                try {
                    const packageJSONPath = findPackageJSONFile(options.cwd);
                    if (packageJSONPath) {
                        let packageJSONOptions;
                        try {
                            packageJSONOptions = JSON.parse((0, fs_1.readFileSync)(packageJSONPath, 'utf8'));
                        }
                        catch (e) {
                            debug('Could not read package.json file to check eslintIgnore property');
                            e.messageTemplate = 'failed-to-read-json';
                            e.messageData = {
                                path: packageJSONPath,
                                message: e.message
                            };
                            throw e;
                        }
                        if (packageJSONOptions.eslintIgnore) {
                            if (Array.isArray(packageJSONOptions.eslintIgnore)) {
                                packageJSONOptions.eslintIgnore.forEach(pattern => {
                                    this.addPatternRelativeToIgnoreFile(this.ig.custom, pattern);
                                    this.addPatternRelativeToIgnoreFile(this.ig.default, pattern);
                                });
                            }
                            else {
                                throw new TypeError('Package.json eslintIgnore property requires an array of paths');
                            }
                        }
                    }
                }
                catch (e) {
                    debug('Could not find package.json to check eslintIgnore property');
                    throw e;
                }
            }
            if (options.ignorePattern) {
                this.addPatternRelativeToCwd(this.ig.custom, options.ignorePattern);
                this.addPatternRelativeToCwd(this.ig.default, options.ignorePattern);
            }
        }
    }
    addPatternRelativeToCwd(ig, pattern) {
        const baseDir = this.getBaseDir();
        const cookedPattern = baseDir === this.options.cwd
            ? pattern
            : relativize(pattern, (0, path_1.relative)(baseDir, this.options.cwd));
        ig.add(cookedPattern);
        debug('addPatternRelativeToCwd:\n  original = %j\n  cooked   = %j', pattern, cookedPattern);
    }
    addPatternRelativeToIgnoreFile(ig, pattern) {
        const baseDir = this.getBaseDir();
        const cookedPattern = baseDir === this.ignoreFileDir
            ? pattern
            : relativize(pattern, (0, path_1.relative)(baseDir, this.ignoreFileDir));
        ig.add(cookedPattern);
        debug('addPatternRelativeToIgnoreFile:\n  original = %j\n  cooked   = %j', pattern, cookedPattern);
    }
    getBaseDir() {
        if (!this._baseDir) {
            const a = (0, path_1.resolve)(this.options.cwd);
            const b = (0, path_1.resolve)(this.ignoreFileDir);
            let lastSepPos = 0;
            this._baseDir = a.length < b.length ? a : b;
            for (let i = 0; i < a.length && i < b.length; ++i) {
                if (a[i] !== b[i]) {
                    this._baseDir = a.slice(0, lastSepPos);
                    break;
                }
                if (a[i] === path_1.sep) {
                    lastSepPos = i;
                }
            }
            if (/^[A-Z]:$/.test(this._baseDir)) {
                this._baseDir += '\\';
            }
            debug('set baseDir = %j', this._baseDir);
        }
        else {
            debug('alredy set baseDir = %j', this._baseDir);
        }
        return this._baseDir;
    }
    readIgnoreFile(filePath) {
        if (typeof this.cache[filePath] === 'undefined') {
            this.cache[filePath] = (0, fs_1.readFileSync)(filePath, 'utf8')
                .split(/\r?\n/g)
                .filter(Boolean);
        }
        return this.cache[filePath];
    }
    addIgnoreFile(ig, filePath) {
        ig.ignoreFiles.push(filePath);
        this.readIgnoreFile(filePath).forEach(ignoreRule => this.addPatternRelativeToIgnoreFile(ig, ignoreRule));
    }
    contains(filepath, category) {
        let result = false;
        const absolutePath = (0, path_1.resolve)(this.options.cwd, filepath);
        const relativePath = (0, path_utils_1.getRelativePath)(absolutePath, this.getBaseDir());
        if (typeof category === 'undefined') {
            result =
                this.ig.default.filter([relativePath]).length === 0 ||
                    this.ig.custom.filter([relativePath]).length === 0;
        }
        else {
            result = this.ig[category].filter([relativePath]).length === 0;
        }
        debug('contains:');
        debug('  target = %j', filepath);
        debug('  result = %j', result);
        return result;
    }
    getIgnoredFoldersGlobChecker() {
        const baseDir = this.getBaseDir();
        const ig = (0, ignore_1.default)();
        DEFAULT_IGNORE_DIRS.forEach(ignoreDir => this.addPatternRelativeToCwd(ig, ignoreDir));
        if (this.options.dotfiles !== true) {
            ig.add(['.*/*', '!../*']);
        }
        if (this.options.ignore) {
            ig.add(this.ig.custom);
        }
        const filter = ig.createFilter();
        return function (absolutePath) {
            const relative = (0, path_utils_1.getRelativePath)(absolutePath.fullpath(), baseDir);
            if (!relative) {
                return false;
            }
            return !filter(relative);
        };
    }
}
exports.IgnoredPaths = IgnoredPaths;
