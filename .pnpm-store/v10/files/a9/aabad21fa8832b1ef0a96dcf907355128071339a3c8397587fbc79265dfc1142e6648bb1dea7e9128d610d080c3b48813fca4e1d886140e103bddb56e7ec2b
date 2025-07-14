"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.listFilesToProcess = exports.resolveFileGlobPatterns = void 0;
const lodash_1 = require("lodash");
const fs_1 = require("fs");
const path_1 = require("path");
const glob_1 = require("glob");
const path_utils_1 = require("./path-utils");
const ignored_paths_1 = require("./ignored-paths");
const debug_1 = __importDefault(require("debug"));
const debug = (0, debug_1.default)('eslint-plugin-vue-i18n:glob-utils');
function directoryExists(resolvedPath) {
    return (0, fs_1.existsSync)(resolvedPath) && (0, fs_1.statSync)(resolvedPath).isDirectory();
}
function processPath(options) {
    const cwd = (options && options.cwd) || process.cwd();
    let extensions = (options && options.extensions) || ['.js'];
    extensions = extensions.map(ext => ext.replace(/^\./, ''));
    let suffix = '/**';
    if (extensions.length === 1) {
        suffix += `/*.${extensions[0]}`;
    }
    else {
        suffix += `/*.{${extensions.join(',')}}`;
    }
    return function (pathname) {
        let newPath = pathname;
        const resolvedPath = (0, path_1.resolve)(cwd, pathname);
        if (directoryExists(resolvedPath)) {
            newPath = pathname.replace(/[/\\]$/, '') + suffix;
        }
        return (0, path_utils_1.convertPathToPosix)(newPath);
    };
}
class NoFilesFoundError extends Error {
    constructor(pattern) {
        super(`No files matching '${pattern}' were found.`);
        this.messageTemplate = 'file-not-found';
        this.messageData = { pattern };
    }
}
class AllFilesIgnoredError extends Error {
    constructor(pattern) {
        super(`All files matched by '${pattern}' are ignored.`);
        this.messageTemplate = 'all-files-ignored';
        this.messageData = { pattern };
    }
}
const NORMAL_LINT = {};
const SILENTLY_IGNORE = {};
const IGNORE_AND_WARN = {};
function testFileAgainstIgnorePatterns(filename, options, isDirectPath, ignoredPaths) {
    const shouldProcessCustomIgnores = options.ignore !== false;
    const shouldLintIgnoredDirectPaths = options.ignore === false;
    const fileMatchesIgnorePatterns = ignoredPaths.contains(filename, 'default') ||
        (shouldProcessCustomIgnores && ignoredPaths.contains(filename, 'custom'));
    if (fileMatchesIgnorePatterns &&
        isDirectPath &&
        !shouldLintIgnoredDirectPaths) {
        return IGNORE_AND_WARN;
    }
    if (!fileMatchesIgnorePatterns ||
        (isDirectPath && shouldLintIgnoredDirectPaths)) {
        return NORMAL_LINT;
    }
    return SILENTLY_IGNORE;
}
function resolveFileGlobPatterns(patterns, options) {
    if (options.globInputPaths === false) {
        return patterns;
    }
    const processPathExtensions = processPath(options);
    return patterns.map(processPathExtensions);
}
exports.resolveFileGlobPatterns = resolveFileGlobPatterns;
const dotfilesPattern = /(?:(?:^\.)|(?:[/\\]\.))[^/\\.].*/;
function listFilesToProcess(globPatterns, providedOptions) {
    const options = providedOptions || { ignore: true };
    const cwd = options.cwd || process.cwd();
    const getIgnorePaths = (optionsObj) => new ignored_paths_1.IgnoredPaths(optionsObj);
    const resolvedGlobPatterns = resolveFileGlobPatterns(globPatterns, options);
    debug('Creating list of files to process.');
    const resolvedPathsByGlobPattern = resolvedGlobPatterns.map(pattern => {
        const file = (0, path_1.resolve)(cwd, pattern);
        if (options.globInputPaths === false ||
            ((0, fs_1.existsSync)(file) && (0, fs_1.statSync)(file).isFile())) {
            const ignoredPaths = getIgnorePaths(options);
            const fullPath = options.globInputPaths === false ? file : (0, fs_1.realpathSync)(file);
            return [
                {
                    filename: fullPath,
                    behavior: testFileAgainstIgnorePatterns(fullPath, options, true, ignoredPaths)
                }
            ];
        }
        const globIncludesDotfiles = dotfilesPattern.test(pattern);
        let newOptions = options;
        if (!options.dotfiles) {
            newOptions = Object.assign({}, options, {
                dotfiles: globIncludesDotfiles
            });
        }
        const ignoredPaths = getIgnorePaths(newOptions);
        const shouldIgnore = ignoredPaths.getIgnoredFoldersGlobChecker();
        const globOptions = {
            nodir: true,
            dot: true,
            cwd,
            ignore: { ignored: shouldIgnore }
        };
        return (0, glob_1.globSync)(pattern, globOptions).map(globMatch => {
            if (typeof globMatch !== 'string')
                return;
            const relativePath = (0, path_1.resolve)(cwd, globMatch);
            return {
                filename: relativePath,
                behavior: testFileAgainstIgnorePatterns(relativePath, options, false, ignoredPaths)
            };
        });
    });
    const allPathDescriptors = resolvedPathsByGlobPattern.reduce((pathsForAllGlobs, pathsForCurrentGlob, index) => {
        if (pathsForCurrentGlob.every(pathDescriptor => (pathDescriptor === null || pathDescriptor === void 0 ? void 0 : pathDescriptor.behavior) === SILENTLY_IGNORE)) {
            throw new (pathsForCurrentGlob.length ? AllFilesIgnoredError : NoFilesFoundError)(globPatterns[index]);
        }
        pathsForCurrentGlob.forEach(pathDescriptor => {
            switch (pathDescriptor === null || pathDescriptor === void 0 ? void 0 : pathDescriptor.behavior) {
                case NORMAL_LINT:
                    pathsForAllGlobs.push({
                        filename: pathDescriptor.filename,
                        ignored: false
                    });
                    break;
                case IGNORE_AND_WARN:
                    pathsForAllGlobs.push({
                        filename: pathDescriptor.filename,
                        ignored: true
                    });
                    break;
                case SILENTLY_IGNORE:
                    break;
                default:
                    throw new Error(`Unexpected file behavior for ${pathDescriptor === null || pathDescriptor === void 0 ? void 0 : pathDescriptor.filename}`);
            }
        });
        return pathsForAllGlobs;
    }, []);
    const ret = (0, lodash_1.uniqBy)(allPathDescriptors, pathDescriptor => pathDescriptor.filename);
    debug(ret);
    return ret;
}
exports.listFilesToProcess = listFilesToProcess;
