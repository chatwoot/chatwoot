"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useCaseSensitiveFileNames = exports.isReferencedFile = exports.supportsSolutionBuild = exports.ensureProgram = exports.arrify = exports.collectAllDependants = exports.populateReverseDependencyGraph = exports.populateDependencyGraph = exports.unorderedRemoveItem = exports.appendSuffixesIfMatch = exports.appendSuffixIfMatch = exports.tsLoaderSource = exports.makeError = exports.fsReadFile = exports.formatErrors = void 0;
const fs = require("fs");
const micromatch = require("micromatch");
const path = require("path");
const constants = require("./constants");
const instances_1 = require("./instances");
/**
 * The default error formatter.
 */
function defaultErrorFormatter(error, colors) {
    const messageColor = error.severity === 'warning' ? colors.bold.yellow : colors.bold.red;
    return (colors.grey('[tsl] ') +
        messageColor(error.severity.toUpperCase()) +
        (error.file === ''
            ? ''
            : messageColor(' in ') +
                colors.bold.cyan(`${error.file}(${error.line},${error.character})`)) +
        constants.EOL +
        messageColor(`      TS${error.code}: ${error.content}`));
}
/**
 * Take TypeScript errors, parse them and format to webpack errors
 * Optionally adds a file name
 */
function formatErrors(diagnostics, loaderOptions, colors, compiler, merge, context) {
    return diagnostics === undefined
        ? []
        : diagnostics
            .filter(diagnostic => {
            if (loaderOptions.ignoreDiagnostics.indexOf(diagnostic.code) !== -1) {
                return false;
            }
            if (loaderOptions.reportFiles.length > 0 &&
                diagnostic.file !== undefined) {
                const relativeFileName = path.relative(context, diagnostic.file.fileName);
                const matchResult = micromatch([relativeFileName], loaderOptions.reportFiles);
                if (matchResult.length === 0) {
                    return false;
                }
            }
            return true;
        })
            .map(diagnostic => {
            const file = diagnostic.file;
            const { start, end } = file === undefined || diagnostic.start === undefined
                ? { start: undefined, end: undefined }
                : getFileLocations(file, diagnostic.start, diagnostic.length);
            const errorInfo = {
                code: diagnostic.code,
                severity: compiler.DiagnosticCategory[diagnostic.category].toLowerCase(),
                content: compiler.flattenDiagnosticMessageText(diagnostic.messageText, constants.EOL),
                file: file === undefined ? '' : path.normalize(file.fileName),
                line: start === undefined ? 0 : start.line,
                character: start === undefined ? 0 : start.character,
                context,
            };
            const message = loaderOptions.errorFormatter === undefined
                ? defaultErrorFormatter(errorInfo, colors)
                : loaderOptions.errorFormatter(errorInfo, colors);
            const error = makeError(loaderOptions, message, merge.file === undefined ? errorInfo.file : merge.file, start, end);
            return Object.assign(error, merge);
        });
}
exports.formatErrors = formatErrors;
function getFileLocations(file, position, length = 0) {
    const startLC = file.getLineAndCharacterOfPosition(position);
    const start = {
        line: startLC.line + 1,
        character: startLC.character + 1,
    };
    const endLC = length > 0
        ? file.getLineAndCharacterOfPosition(position + length)
        : undefined;
    const end = endLC === undefined
        ? undefined
        : { line: endLC.line + 1, character: endLC.character + 1 };
    return { start, end };
}
function fsReadFile(fileName, encoding = 'utf8') {
    fileName = path.normalize(fileName);
    try {
        return fs.readFileSync(fileName, encoding);
    }
    catch (e) {
        return undefined;
    }
}
exports.fsReadFile = fsReadFile;
function makeError(loaderOptions, message, file, location, endLocation) {
    return {
        message,
        file,
        loc: location === undefined
            ? undefined
            : makeWebpackLocation(location, endLocation),
        location,
        loaderSource: tsLoaderSource(loaderOptions),
    };
}
exports.makeError = makeError;
function makeWebpackLocation(location, endLocation) {
    const start = {
        line: location.line,
        column: location.character - 1,
    };
    const end = endLocation === undefined
        ? undefined
        : { line: endLocation.line, column: endLocation.character - 1 };
    return { start, end };
}
function tsLoaderSource(loaderOptions) {
    return `ts-loader-${loaderOptions.instance}`;
}
exports.tsLoaderSource = tsLoaderSource;
function appendSuffixIfMatch(patterns, filePath, suffix) {
    if (patterns.length > 0) {
        for (const regexp of patterns) {
            if (filePath.match(regexp) !== null) {
                return filePath + suffix;
            }
        }
    }
    return filePath;
}
exports.appendSuffixIfMatch = appendSuffixIfMatch;
function appendSuffixesIfMatch(suffixDict, filePath) {
    let amendedPath = filePath;
    for (const suffix in suffixDict) {
        amendedPath = appendSuffixIfMatch(suffixDict[suffix], amendedPath, suffix);
    }
    return amendedPath;
}
exports.appendSuffixesIfMatch = appendSuffixesIfMatch;
function unorderedRemoveItem(array, item) {
    for (let i = 0; i < array.length; i++) {
        if (array[i] === item) {
            // Fill in the "hole" left at `index`.
            array[i] = array[array.length - 1];
            array.pop();
            return true;
        }
    }
    return false;
}
exports.unorderedRemoveItem = unorderedRemoveItem;
function populateDependencyGraph(resolvedModules, instance, containingFile) {
    resolvedModules = resolvedModules.filter(mod => mod !== null && mod !== undefined);
    if (resolvedModules.length) {
        const containingFileKey = instance.filePathKeyMapper(containingFile);
        instance.dependencyGraph.set(containingFileKey, resolvedModules);
    }
}
exports.populateDependencyGraph = populateDependencyGraph;
function populateReverseDependencyGraph(instance) {
    const reverseDependencyGraph = new Map();
    for (const [fileKey, resolvedModules] of instance.dependencyGraph.entries()) {
        const inputFileName = instance.solutionBuilderHost &&
            instances_1.getInputFileNameFromOutput(instance, fileKey);
        const containingFileKey = inputFileName
            ? instance.filePathKeyMapper(inputFileName)
            : fileKey;
        resolvedModules.forEach(({ resolvedFileName }) => {
            const key = instance.filePathKeyMapper(instance.solutionBuilderHost
                ? instances_1.getInputFileNameFromOutput(instance, resolvedFileName) ||
                    resolvedFileName
                : resolvedFileName);
            let map = reverseDependencyGraph.get(key);
            if (!map) {
                map = new Map();
                reverseDependencyGraph.set(key, map);
            }
            map.set(containingFileKey, true);
        });
    }
    return reverseDependencyGraph;
}
exports.populateReverseDependencyGraph = populateReverseDependencyGraph;
/**
 * Recursively collect all possible dependants of passed file
 */
function collectAllDependants(reverseDependencyGraph, fileName, result = new Map()) {
    result.set(fileName, true);
    const dependants = reverseDependencyGraph.get(fileName);
    if (dependants !== undefined) {
        for (const dependantFileName of dependants.keys()) {
            if (!result.has(dependantFileName)) {
                collectAllDependants(reverseDependencyGraph, dependantFileName, result);
            }
        }
    }
    return result;
}
exports.collectAllDependants = collectAllDependants;
function arrify(val) {
    if (val === null || val === undefined) {
        return [];
    }
    return Array.isArray(val) ? val : [val];
}
exports.arrify = arrify;
function ensureProgram(instance) {
    if (instance && instance.watchHost) {
        if (instance.hasUnaccountedModifiedFiles) {
            if (instance.changedFilesList) {
                instance.watchHost.updateRootFileNames();
            }
            if (instance.watchOfFilesAndCompilerOptions) {
                instance.builderProgram = instance.watchOfFilesAndCompilerOptions.getProgram();
                instance.program = instance.builderProgram.getProgram();
            }
            instance.hasUnaccountedModifiedFiles = false;
        }
        return instance.program;
    }
    if (instance.languageService) {
        return instance.languageService.getProgram();
    }
    return instance.program;
}
exports.ensureProgram = ensureProgram;
function supportsSolutionBuild(instance) {
    return (!!instance.configFilePath &&
        !!instance.loaderOptions.projectReferences &&
        !!instance.configParseResult.projectReferences &&
        !!instance.configParseResult.projectReferences.length);
}
exports.supportsSolutionBuild = supportsSolutionBuild;
function isReferencedFile(instance, filePath) {
    return (!!instance.solutionBuilderHost &&
        !!instance.solutionBuilderHost.watchedFiles.get(instance.filePathKeyMapper(filePath)));
}
exports.isReferencedFile = isReferencedFile;
function useCaseSensitiveFileNames(compiler, loaderOptions) {
    return loaderOptions.useCaseSensitiveFileNames !== undefined
        ? loaderOptions.useCaseSensitiveFileNames
        : compiler.sys.useCaseSensitiveFileNames;
}
exports.useCaseSensitiveFileNames = useCaseSensitiveFileNames;
//# sourceMappingURL=utils.js.map