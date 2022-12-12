"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getSolutionErrors = exports.makeSolutionBuilderHost = exports.makeWatchHost = exports.updateFileWithText = exports.makeServicesHost = void 0;
const path = require("path");
const config_1 = require("./config");
const constants = require("./constants");
const instances_1 = require("./instances");
const resolver_1 = require("./resolver");
const utils_1 = require("./utils");
function makeResolversAndModuleResolutionHost(scriptRegex, loader, instance, fileExists, enableFileCaching) {
    const { compiler, compilerOptions, appendTsTsxSuffixesIfRequired, loaderOptions: { resolveModuleName: customResolveModuleName, resolveTypeReferenceDirective: customResolveTypeReferenceDirective, }, } = instance;
    const newLine = compilerOptions.newLine === constants.CarriageReturnLineFeedCode
        ? constants.CarriageReturnLineFeed
        : compilerOptions.newLine === constants.LineFeedCode
            ? constants.LineFeed
            : constants.EOL;
    // loader.context seems to work fine on Linux / Mac regardless causes problems for @types resolution on Windows for TypeScript < 2.3
    const getCurrentDirectory = () => loader.context;
    // make a (sync) resolver that follows webpack's rules
    const resolveSync = resolver_1.makeResolver(loader._compiler.options);
    const moduleResolutionHost = {
        trace: logData => instance.log.log(logData),
        fileExists,
        readFile,
        realpath: compiler.sys.realpath && realpath,
        directoryExists,
        getCurrentDirectory,
        getDirectories,
        readDirectory,
        useCaseSensitiveFileNames: () => utils_1.useCaseSensitiveFileNames(compiler, instance.loaderOptions),
        getNewLine: () => newLine,
        getDefaultLibFileName: options => compiler.getDefaultLibFilePath(options),
    };
    if (enableFileCaching) {
        addCache(moduleResolutionHost);
    }
    return makeResolvers(compiler, compilerOptions, moduleResolutionHost, customResolveTypeReferenceDirective, customResolveModuleName, resolveSync, appendTsTsxSuffixesIfRequired, scriptRegex, instance);
    function readFile(filePath, encoding) {
        return (instance.compiler.sys.readFile(filePath, encoding) ||
            utils_1.fsReadFile(filePath, encoding));
    }
    function directoryExists(directoryName) {
        return compiler.sys.directoryExists(directoryName);
    }
    function realpath(path) {
        return compiler.sys.realpath(path);
    }
    function getDirectories(path) {
        return compiler.sys.getDirectories(path);
    }
    function readDirectory(path, extensions, exclude, include, depth) {
        return compiler.sys.readDirectory(path, extensions, exclude, include, depth);
    }
}
/**
 * Create the TypeScript language service
 */
function makeServicesHost(scriptRegex, loader, instance, projectReferences) {
    const { compiler, compilerOptions, files, filePathKeyMapper } = instance;
    const { moduleResolutionHost, resolveModuleNames, resolveTypeReferenceDirectives, } = makeResolversAndModuleResolutionHost(scriptRegex, loader, instance, filePathToCheck => compiler.sys.fileExists(filePathToCheck) ||
        utils_1.fsReadFile(filePathToCheck) !== undefined, instance.loaderOptions.experimentalFileCaching);
    const servicesHost = Object.assign(Object.assign({ getProjectVersion: () => `${instance.version}`, getProjectReferences: () => projectReferences, getScriptFileNames: () => [...files.values()]
            .map(({ fileName }) => fileName)
            .filter(filePath => filePath.match(scriptRegex)), getScriptVersion: (fileName) => {
            var _a;
            fileName = path.normalize(fileName);
            const key = filePathKeyMapper(fileName);
            const file = files.get(key);
            if (file) {
                return file.version.toString();
            }
            const outputFileAndKey = (_a = instance.solutionBuilderHost) === null || _a === void 0 ? void 0 : _a.getOutputFileAndKeyFromReferencedProject(fileName);
            if (outputFileAndKey !== undefined) {
                instance.solutionBuilderHost.outputAffectingInstanceVersion.set(outputFileAndKey.key, true);
            }
            return outputFileAndKey && outputFileAndKey.outputFile
                ? outputFileAndKey.outputFile
                : '';
        }, getScriptSnapshot: (fileName) => {
            // This is called any time TypeScript needs a file's text
            // We either load from memory or from disk
            fileName = path.normalize(fileName);
            const key = filePathKeyMapper(fileName);
            let file = files.get(key);
            if (file === undefined) {
                if (instance.solutionBuilderHost) {
                    const outputFileAndKey = instance.solutionBuilderHost.getOutputFileTextAndKeyFromReferencedProject(fileName);
                    if (outputFileAndKey !== undefined) {
                        instance.solutionBuilderHost.outputAffectingInstanceVersion.set(outputFileAndKey.key, true);
                        return outputFileAndKey && outputFileAndKey.text !== undefined
                            ? compiler.ScriptSnapshot.fromString(outputFileAndKey.text)
                            : undefined;
                    }
                }
                const text = moduleResolutionHost.readFile(fileName);
                if (text === undefined) {
                    return undefined;
                }
                file = { fileName, version: 0, text };
                files.set(key, file);
            }
            return compiler.ScriptSnapshot.fromString(file.text);
        } }, moduleResolutionHost), { getCompilationSettings: () => compilerOptions, log: moduleResolutionHost.trace, 
        // used for (/// <reference types="...">) see https://github.com/Realytics/fork-ts-checker-webpack-plugin/pull/250#issuecomment-485061329
        resolveTypeReferenceDirectives,
        resolveModuleNames, getCustomTransformers: () => instance.transformers });
    return servicesHost;
}
exports.makeServicesHost = makeServicesHost;
function makeResolvers(compiler, compilerOptions, moduleResolutionHost, customResolveTypeReferenceDirective, customResolveModuleName, resolveSync, appendTsTsxSuffixesIfRequired, scriptRegex, instance) {
    const resolveModuleName = makeResolveModuleName(compiler, compilerOptions, moduleResolutionHost, customResolveModuleName, instance);
    const resolveModuleNames = (moduleNames, containingFile, _reusedNames, redirectedReference) => {
        const resolvedModules = moduleNames.map(moduleName => resolveModule(resolveSync, resolveModuleName, appendTsTsxSuffixesIfRequired, scriptRegex, moduleName, containingFile, redirectedReference));
        utils_1.populateDependencyGraph(resolvedModules, instance, containingFile);
        return resolvedModules;
    };
    const resolveTypeReferenceDirective = makeResolveTypeReferenceDirective(compiler, compilerOptions, moduleResolutionHost, customResolveTypeReferenceDirective, instance);
    const resolveTypeReferenceDirectives = (typeDirectiveNames, containingFile, redirectedReference) => typeDirectiveNames.map(directive => resolveTypeReferenceDirective(directive, containingFile, redirectedReference).resolvedTypeReferenceDirective);
    return {
        resolveTypeReferenceDirectives,
        resolveModuleNames,
        moduleResolutionHost,
    };
}
function createWatchFactory(filePathKeyMapper, compiler) {
    const watchedFiles = new Map();
    const watchedDirectories = new Map();
    const watchedDirectoriesRecursive = new Map();
    return {
        watchedFiles,
        watchedDirectories,
        watchedDirectoriesRecursive,
        invokeFileWatcher,
        watchFile,
        watchDirectory,
    };
    function invokeWatcherCallbacks(map, key, fileName, eventKind) {
        var _a;
        const callbacks = (_a = map.get(filePathKeyMapper(key))) === null || _a === void 0 ? void 0 : _a.callbacks;
        if (callbacks !== undefined && callbacks.length) {
            // The array copy is made to ensure that even if one of the callback removes the callbacks,
            // we dont miss any callbacks following it
            const cbs = callbacks.slice();
            for (const cb of cbs) {
                cb(fileName, eventKind);
            }
            return true;
        }
        return false;
    }
    function invokeFileWatcher(fileName, eventKind) {
        fileName = path.normalize(fileName);
        let result = invokeWatcherCallbacks(watchedFiles, fileName, fileName, eventKind);
        if (eventKind !== compiler.FileWatcherEventKind.Changed) {
            const directory = path.dirname(fileName);
            result =
                invokeWatcherCallbacks(watchedDirectories, directory, fileName) ||
                    result;
            result = invokeRecursiveDirectoryWatcher(directory, fileName) || result;
        }
        return result;
    }
    ``;
    function invokeRecursiveDirectoryWatcher(directory, fileAddedOrRemoved) {
        directory = path.normalize(directory);
        let result = invokeWatcherCallbacks(watchedDirectoriesRecursive, directory, fileAddedOrRemoved);
        const basePath = path.dirname(directory);
        if (directory !== basePath) {
            result =
                invokeRecursiveDirectoryWatcher(basePath, fileAddedOrRemoved) || result;
        }
        return result;
    }
    function createWatcher(file, callbacks, callback) {
        const key = filePathKeyMapper(file);
        const existing = callbacks.get(key);
        if (existing === undefined) {
            callbacks.set(key, {
                fileName: path.normalize(file),
                callbacks: [callback],
            });
        }
        else {
            existing.callbacks.push(callback);
        }
        return {
            close: () => {
                const existing = callbacks.get(key);
                if (existing !== undefined) {
                    utils_1.unorderedRemoveItem(existing.callbacks, callback);
                    if (!existing.callbacks.length) {
                        callbacks.delete(key);
                    }
                }
            },
        };
    }
    function watchFile(fileName, callback, _pollingInterval) {
        return createWatcher(fileName, watchedFiles, callback);
    }
    function watchDirectory(fileName, callback, recursive) {
        return createWatcher(fileName, recursive === true ? watchedDirectoriesRecursive : watchedDirectories, callback);
    }
}
function updateFileWithText(instance, key, filePath, text) {
    const nFilePath = path.normalize(filePath);
    const file = instance.files.get(key) || instance.otherFiles.get(key);
    if (file !== undefined) {
        const newText = text(nFilePath);
        if (newText !== file.text) {
            file.text = newText;
            file.version++;
            file.modifiedTime = new Date();
            instance.version++;
            if (!instance.modifiedFiles) {
                instance.modifiedFiles = new Map();
            }
            instance.modifiedFiles.set(key, true);
            if (instance.watchHost !== undefined) {
                instance.watchHost.invokeFileWatcher(nFilePath, instance.compiler.FileWatcherEventKind.Changed);
            }
        }
    }
}
exports.updateFileWithText = updateFileWithText;
/**
 * Create the TypeScript Watch host
 */
function makeWatchHost(scriptRegex, loader, instance, projectReferences) {
    const { compiler, compilerOptions, files, otherFiles, filePathKeyMapper, } = instance;
    const { watchFile, watchDirectory, invokeFileWatcher } = createWatchFactory(filePathKeyMapper, compiler);
    const { moduleResolutionHost, resolveModuleNames, resolveTypeReferenceDirectives, } = makeResolversAndModuleResolutionHost(scriptRegex, loader, instance, fileName => files.has(filePathKeyMapper(fileName)) ||
        compiler.sys.fileExists(fileName), instance.loaderOptions.experimentalFileCaching);
    const watchHost = Object.assign(Object.assign({ rootFiles: getRootFileNames(), options: compilerOptions }, moduleResolutionHost), { readFile: readFileWithCachingText, watchFile: (fileName, callback, pollingInterval, options) => {
            var _a;
            const outputFileKey = (_a = instance.solutionBuilderHost) === null || _a === void 0 ? void 0 : _a.getOutputFileKeyFromReferencedProject(fileName);
            if (!outputFileKey || outputFileKey === filePathKeyMapper(fileName)) {
                return watchFile(fileName, callback, pollingInterval, options);
            }
            // Handle symlink to outputFile
            const outputFileName = instance.solutionBuilderHost.realpath(fileName);
            return watchFile(outputFileName, (_fileName, eventKind) => callback(fileName, eventKind), pollingInterval, options);
        }, watchDirectory,
        // used for (/// <reference types="...">) see https://github.com/Realytics/fork-ts-checker-webpack-plugin/pull/250#issuecomment-485061329
        resolveTypeReferenceDirectives,
        resolveModuleNames,
        invokeFileWatcher, updateRootFileNames: () => {
            instance.changedFilesList = false;
            if (instance.watchOfFilesAndCompilerOptions !== undefined) {
                instance.watchOfFilesAndCompilerOptions.updateRootFileNames(getRootFileNames());
            }
        }, createProgram: projectReferences === undefined
            ? compiler.createEmitAndSemanticDiagnosticsBuilderProgram
            : createBuilderProgramWithReferences, outputFiles: new Map() });
    return watchHost;
    function getRootFileNames() {
        return [...files.values()]
            .map(({ fileName }) => fileName)
            .filter(filePath => filePath.match(scriptRegex));
    }
    function readFileWithCachingText(fileName, encoding) {
        var _a;
        fileName = path.normalize(fileName);
        const key = filePathKeyMapper(fileName);
        const file = files.get(key) || otherFiles.get(key);
        if (file !== undefined) {
            return file.text;
        }
        const text = moduleResolutionHost.readFile(fileName, encoding);
        if (text === undefined) {
            return undefined;
        }
        if (!((_a = instance.solutionBuilderHost) === null || _a === void 0 ? void 0 : _a.getOutputFileKeyFromReferencedProject(fileName))) {
            otherFiles.set(key, { fileName, version: 0, text });
        }
        return text;
    }
    function createBuilderProgramWithReferences(rootNames, options, host, oldProgram, configFileParsingDiagnostics) {
        const program = compiler.createProgram({
            rootNames: rootNames,
            options: options,
            host,
            oldProgram: oldProgram && oldProgram.getProgram(),
            configFileParsingDiagnostics,
            projectReferences,
        });
        const builderProgramHost = host;
        return compiler.createEmitAndSemanticDiagnosticsBuilderProgram(program, builderProgramHost, oldProgram, configFileParsingDiagnostics);
    }
}
exports.makeWatchHost = makeWatchHost;
const missingFileModifiedTime = new Date(0);
function identity(x) {
    return x;
}
function toLowerCase(x) {
    return x.toLowerCase();
}
const fileNameLowerCaseRegExp = /[^\u0130\u0131\u00DFa-z0-9\\/:\-_\. ]+/g;
function toFileNameLowerCase(x) {
    return fileNameLowerCaseRegExp.test(x)
        ? x.replace(fileNameLowerCaseRegExp, toLowerCase)
        : x;
}
function createGetCanonicalFileName(instance) {
    return utils_1.useCaseSensitiveFileNames(instance.compiler, instance.loaderOptions)
        ? identity
        : toFileNameLowerCase;
}
function createModuleResolutionCache(instance, moduleResolutionHost) {
    const cache = instance.compiler.createModuleResolutionCache(moduleResolutionHost.getCurrentDirectory(), createGetCanonicalFileName(instance), instance.compilerOptions);
    // Add new API optional methods
    if (!cache.clear) {
        cache.clear = () => {
            cache.directoryToModuleNameMap.clear();
            cache.moduleNameToDirectoryMap.clear();
        };
    }
    if (!cache.update) {
        cache.update = options => {
            if (!options.configFile)
                return;
            const ref = {
                sourceFile: options.configFile,
                commandLine: { options },
            };
            cache.directoryToModuleNameMap.setOwnMap(cache.directoryToModuleNameMap.getOrCreateMapOfCacheRedirects(ref));
            cache.moduleNameToDirectoryMap.setOwnMap(cache.moduleNameToDirectoryMap.getOrCreateMapOfCacheRedirects(ref));
            cache.directoryToModuleNameMap.setOwnOptions(options);
            cache.moduleNameToDirectoryMap.setOwnOptions(options);
        };
    }
    return cache;
}
/**
 * Create the TypeScript Watch host
 */
function makeSolutionBuilderHost(scriptRegex, loader, instance) {
    const { compiler, loaderOptions: { transpileOnly }, filePathKeyMapper, } = instance;
    // loader.context seems to work fine on Linux / Mac regardless causes problems for @types resolution on Windows for TypeScript < 2.3
    const formatDiagnosticHost = {
        getCurrentDirectory: compiler.sys.getCurrentDirectory,
        getCanonicalFileName: createGetCanonicalFileName(instance),
        getNewLine: () => compiler.sys.newLine,
    };
    const diagnostics = {
        global: [],
        perFile: new Map(),
        transpileErrors: [],
    };
    const reportDiagnostic = (d) => {
        if (transpileOnly) {
            const filePath = d.file ? filePathKeyMapper(d.file.fileName) : undefined;
            const last = diagnostics.transpileErrors[diagnostics.transpileErrors.length - 1];
            if (diagnostics.transpileErrors.length && last[0] === filePath) {
                last[1].push(d);
            }
            else {
                diagnostics.transpileErrors.push([filePath, [d]]);
            }
        }
        else if (d.file) {
            const filePath = filePathKeyMapper(d.file.fileName);
            const existing = diagnostics.perFile.get(filePath);
            if (existing) {
                existing.push(d);
            }
            else {
                diagnostics.perFile.set(filePath, [d]);
            }
        }
        else {
            diagnostics.global.push(d);
        }
        instance.log.logInfo(compiler.formatDiagnostic(d, formatDiagnosticHost));
    };
    const reportSolutionBuilderStatus = (d) => instance.log.logInfo(compiler.formatDiagnostic(d, formatDiagnosticHost));
    const reportWatchStatus = (d, newLine, _options) => instance.log.logInfo(`${compiler.flattenDiagnosticMessageText(d.messageText, compiler.sys.newLine)}${newLine + newLine}`);
    const outputFiles = new Map();
    const inputFiles = new Map();
    const writtenFiles = [];
    const outputAffectingInstanceVersion = new Map();
    let timeoutId;
    const { resolveModuleNames, resolveTypeReferenceDirectives, moduleResolutionHost, } = makeResolversAndModuleResolutionHost(scriptRegex, loader, instance, fileName => {
        const filePathKey = filePathKeyMapper(fileName);
        return (instance.files.has(filePathKey) ||
            instance.otherFiles.has(filePathKey) ||
            compiler.sys.fileExists(fileName));
    }, 
    /*enableFileCaching*/ true);
    const configFileInfo = new Map();
    const allWatches = [];
    const sysHost = compiler.createSolutionBuilderWithWatchHost(compiler.sys, compiler.createEmitAndSemanticDiagnosticsBuilderProgram, reportDiagnostic, reportSolutionBuilderStatus, reportWatchStatus);
    const solutionBuilderHost = Object.assign(Object.assign(Object.assign(Object.assign(Object.assign({}, sysHost), moduleResolutionHost), { createProgram: (rootNames, options, host, oldProgram, configFileParsingDiagnostics, projectReferences) => {
            var _a, _b, _c, _d;
            (_a = instance.moduleResolutionCache) === null || _a === void 0 ? void 0 : _a.update(options || {});
            (_b = instance.typeReferenceResolutionCache) === null || _b === void 0 ? void 0 : _b.update(options || {});
            const result = sysHost.createProgram(rootNames, options, host, oldProgram, configFileParsingDiagnostics, projectReferences);
            (_c = instance.typeReferenceResolutionCache) === null || _c === void 0 ? void 0 : _c.update(instance.compilerOptions);
            (_d = instance.moduleResolutionCache) === null || _d === void 0 ? void 0 : _d.update(instance.compilerOptions);
            return result;
        }, resolveModuleNames,
        resolveTypeReferenceDirectives,
        diagnostics }), createWatchFactory(filePathKeyMapper, compiler)), { 
        // Overrides
        writeFile: (name, text, writeByteOrderMark) => {
            var _a;
            const key = filePathKeyMapper(name);
            updateFileWithText(instance, key, name, () => text);
            const existing = ensureOutputFile(name);
            const hash = hashOutputText(text);
            outputFiles.set(key, hash);
            writtenFiles.push({
                name,
                text,
                writeByteOrderMark: !!writeByteOrderMark,
            });
            compiler.sys.writeFile(name, text, writeByteOrderMark);
            (_a = moduleResolutionHost.fileExistsCache) === null || _a === void 0 ? void 0 : _a.delete(name);
            if (outputAffectingInstanceVersion.has(key) &&
                (!existing || existing !== hash)) {
                instance.version++;
            }
            if (instance.watchHost &&
                !instance.files.has(key) &&
                !instance.otherFiles.has(key)) {
                // If file wasnt updated in files or other files of instance, let watch host know of the change
                if (!existing) {
                    instance.hasUnaccountedModifiedFiles =
                        instance.watchHost.invokeFileWatcher(name, compiler.FileWatcherEventKind.Created) || instance.hasUnaccountedModifiedFiles;
                }
                else if (existing !== hash) {
                    instance.hasUnaccountedModifiedFiles =
                        instance.watchHost.invokeFileWatcher(name, compiler.FileWatcherEventKind.Changed) || instance.hasUnaccountedModifiedFiles;
                }
            }
        }, createDirectory: sysHost.createDirectory &&
            (directory => {
                var _a;
                sysHost.createDirectory(directory);
                (_a = moduleResolutionHost.directoryExistsCache) === null || _a === void 0 ? void 0 : _a.delete(directory);
            }), afterProgramEmitAndDiagnostics: transpileOnly ? undefined : storeDtsFiles, setTimeout: (callback, _time, ...args) => {
            timeoutId = [callback, args];
            return timeoutId;
        }, clearTimeout: _timeoutId => {
            timeoutId = undefined;
        }, getParsedCommandLine: file => {
            const config = config_1.getParsedCommandLine(compiler, instance.loaderOptions, file);
            configFileInfo.set(filePathKeyMapper(file), { config });
            return config;
        }, writtenFiles,
        configFileInfo,
        outputAffectingInstanceVersion,
        getInputFileStamp,
        updateSolutionBuilderInputFile,
        getOutputFileKeyFromReferencedProject,
        getOutputFileAndKeyFromReferencedProject,
        getOutputFileTextAndKeyFromReferencedProject, getInputFileNameFromOutput: fileName => {
            const result = getInputFileNameFromOutput(fileName);
            return typeof result === 'string' ? result : undefined;
        }, getOutputFilesFromReferencedProjectInput,
        buildReferences,
        ensureAllReferenceTimestamps,
        clearCache,
        close });
    return solutionBuilderHost;
    function close() {
        allWatches.slice().forEach(w => w.close());
    }
    function clearCache() {
        moduleResolutionHost.clearCache();
        outputFiles.clear();
        inputFiles.clear();
    }
    function buildReferences() {
        if (!timeoutId) {
            ensureAllReferenceTimestamps();
            return;
        }
        diagnostics.global.length = 0;
        diagnostics.perFile.clear();
        diagnostics.transpileErrors.length = 0;
        while (timeoutId) {
            const [callback, args] = timeoutId;
            timeoutId = undefined;
            callback(...args);
        }
        ensureAllReferenceTimestamps();
    }
    function ensureAllReferenceTimestamps() {
        if (inputFiles.size !== solutionBuilderHost.watchedFiles.size) {
            for (const { fileName, } of instance.solutionBuilderHost.watchedFiles.values()) {
                instance.solutionBuilderHost.getInputFileStamp(fileName);
            }
        }
    }
    function storeDtsFiles(builderProgram) {
        const program = builderProgram.getProgram();
        for (const configInfo of configFileInfo.values()) {
            if (!configInfo.config ||
                program.getRootFileNames() !== configInfo.config.fileNames ||
                program.getCompilerOptions() !== configInfo.config.options ||
                program.getProjectReferences() !== configInfo.config.projectReferences) {
                continue;
            }
            configInfo.dtsFiles = program
                .getSourceFiles()
                .map(file => path.resolve(file.fileName))
                .filter(fileName => fileName.match(constants.dtsDtsxOrDtsDtsxMapRegex));
            return;
        }
    }
    function getInputFileNameFromOutput(outputFileName) {
        const resolvedFileName = filePathKeyMapper(outputFileName);
        for (const configInfo of configFileInfo.values()) {
            ensureInputOutputInfo(configInfo);
            if (configInfo.outputFileNames) {
                for (const { inputFileName, outputNames, } of configInfo.outputFileNames.values()) {
                    if (outputNames.some(outputName => resolvedFileName === filePathKeyMapper(outputName))) {
                        return inputFileName;
                    }
                }
            }
            if (configInfo.tsbuildInfoFile &&
                filePathKeyMapper(configInfo.tsbuildInfoFile) === resolvedFileName) {
                return true;
            }
        }
        const realPath = solutionBuilderHost.realpath(outputFileName);
        return filePathKeyMapper(realPath) !== resolvedFileName
            ? getInputFileNameFromOutput(realPath)
            : undefined;
    }
    function ensureInputOutputInfo(configInfo) {
        if (configInfo.outputFileNames || !configInfo.config) {
            return;
        }
        configInfo.outputFileNames = new Map();
        configInfo.config.fileNames.forEach(inputFile => configInfo.outputFileNames.set(filePathKeyMapper(inputFile), {
            inputFileName: path.resolve(inputFile),
            outputNames: instances_1.getOutputFileNames(instance, configInfo.config, inputFile),
        }));
        configInfo.tsbuildInfoFile = instance.compiler
            .getTsBuildInfoEmitOutputFilePath
            ? instance.compiler.getTsBuildInfoEmitOutputFilePath(configInfo.config.options)
            : // before api
                instance.compiler.getOutputPathForBuildInfo(configInfo.config.options);
    }
    function getOutputFileAndKeyFromReferencedProject(outputFileName) {
        const outputFile = ensureOutputFile(outputFileName);
        return outputFile !== undefined
            ? {
                key: getOutputFileKeyFromReferencedProject(outputFileName),
                outputFile,
            }
            : undefined;
    }
    function getOutputFileTextAndKeyFromReferencedProject(outputFileName) {
        const key = getOutputFileKeyFromReferencedProject(outputFileName);
        if (!key) {
            return undefined;
        }
        const file = writtenFiles.find(w => filePathKeyMapper(w.name) === key);
        if (file) {
            return { key, text: file.text };
        }
        const outputFile = outputFiles.get(key);
        return {
            key,
            text: outputFile !== false
                ? compiler.sys.readFile(outputFileName)
                : undefined,
        };
    }
    function getOutputFileKeyFromReferencedProject(outputFileName) {
        const key = filePathKeyMapper(outputFileName);
        if (outputFiles.has(key))
            return key;
        const realKey = filePathKeyMapper(solutionBuilderHost.realpath(outputFileName));
        if (realKey !== key && outputFiles.has(realKey))
            return realKey;
        return getInputFileNameFromOutput(outputFileName) ? realKey : undefined;
    }
    function hashOutputText(text) {
        return compiler.sys.createHash ? compiler.sys.createHash(text) : text;
    }
    function ensureOutputFile(outputFileName) {
        const key = getOutputFileKeyFromReferencedProject(outputFileName);
        if (!key) {
            return undefined;
        }
        const outputFile = outputFiles.get(key);
        if (outputFile !== undefined) {
            return outputFile;
        }
        if (!getInputFileNameFromOutput(outputFileName)) {
            return undefined;
        }
        const text = compiler.sys.readFile(outputFileName);
        const hash = text === undefined ? false : hashOutputText(text);
        outputFiles.set(key, hash);
        return hash;
    }
    function getTypeScriptOutputFile(outputFileName) {
        const key = filePathKeyMapper(outputFileName);
        const writtenFile = writtenFiles.find(w => filePathKeyMapper(w.name) === key);
        if (writtenFile)
            return writtenFile;
        // Read from sys
        const text = compiler.sys.readFile(outputFileName);
        return text !== undefined
            ? {
                name: outputFileName,
                text,
                writeByteOrderMark: false,
            }
            : undefined;
    }
    function getOutputFilesFromReferencedProjectInput(inputFileName) {
        const resolvedFileName = filePathKeyMapper(inputFileName);
        for (const configInfo of configFileInfo.values()) {
            ensureInputOutputInfo(configInfo);
            if (configInfo.outputFileNames) {
                const result = configInfo.outputFileNames.get(resolvedFileName);
                if (result) {
                    return result.outputNames
                        .map(getTypeScriptOutputFile)
                        .filter(output => !!output);
                }
            }
        }
        return [];
    }
    function getInputFileStamp(fileName) {
        const key = filePathKeyMapper(fileName);
        const existing = inputFiles.get(key);
        if (existing !== undefined) {
            return existing;
        }
        const time = compiler.sys.getModifiedTime(fileName) || missingFileModifiedTime;
        inputFiles.set(key, time);
        return time;
    }
    function updateSolutionBuilderInputFile(fileName) {
        const key = filePathKeyMapper(fileName);
        const existing = inputFiles.get(key) || missingFileModifiedTime;
        const newTime = compiler.sys.getModifiedTime(fileName) || missingFileModifiedTime;
        if (existing.getTime() === newTime.getTime()) {
            return;
        }
        const eventKind = existing == missingFileModifiedTime
            ? compiler.FileWatcherEventKind.Created
            : newTime === missingFileModifiedTime
                ? compiler.FileWatcherEventKind.Deleted
                : compiler.FileWatcherEventKind.Changed;
        solutionBuilderHost.invokeFileWatcher(fileName, eventKind);
    }
}
exports.makeSolutionBuilderHost = makeSolutionBuilderHost;
function getSolutionErrors(instance, context) {
    const solutionErrors = [];
    if (instance.solutionBuilderHost &&
        instance.solutionBuilderHost.diagnostics.transpileErrors.length) {
        instance.solutionBuilderHost.diagnostics.transpileErrors.forEach(([filePath, errors]) => solutionErrors.push(...utils_1.formatErrors(errors, instance.loaderOptions, instance.colors, instance.compiler, { file: filePath ? undefined : 'tsconfig.json' }, context)));
    }
    return solutionErrors;
}
exports.getSolutionErrors = getSolutionErrors;
function makeResolveTypeReferenceDirective(compiler, compilerOptions, moduleResolutionHost, customResolveTypeReferenceDirective, instance) {
    var _a, _b;
    if (customResolveTypeReferenceDirective === undefined) {
        // Until the api is published
        if (compiler.createTypeReferenceDirectiveResolutionCache &&
            !instance.typeReferenceResolutionCache) {
            instance.typeReferenceResolutionCache = compiler.createTypeReferenceDirectiveResolutionCache(moduleResolutionHost.getCurrentDirectory(), createGetCanonicalFileName(instance), instance.compilerOptions, (_b = (_a = instance.moduleResolutionCache) === null || _a === void 0 ? void 0 : _a.getPackageJsonInfoCache) === null || _b === void 0 ? void 0 : _b.call(_a));
        }
        return (directive, containingFile, redirectedReference) => 
        // Until the api is published
        compiler.resolveTypeReferenceDirective(directive, containingFile, compilerOptions, moduleResolutionHost, redirectedReference, instance.typeReferenceResolutionCache);
    }
    return (directive, containingFile) => customResolveTypeReferenceDirective(directive, containingFile, compilerOptions, moduleResolutionHost, compiler.resolveTypeReferenceDirective);
}
function isJsImplementationOfTypings(resolvedModule, tsResolution) {
    return (resolvedModule.resolvedFileName.endsWith('js') &&
        /\.d\.ts$/.test(tsResolution.resolvedFileName));
}
function resolveModule(resolveSync, resolveModuleName, appendTsTsxSuffixesIfRequired, scriptRegex, moduleName, containingFile, redirectedReference) {
    let resolutionResult;
    try {
        const originalFileName = resolveSync(undefined, path.normalize(path.dirname(containingFile)), moduleName);
        const resolvedFileName = appendTsTsxSuffixesIfRequired(originalFileName);
        if (resolvedFileName.match(scriptRegex) !== null) {
            resolutionResult = { resolvedFileName, originalFileName };
        }
    }
    catch (e) { }
    const tsResolution = resolveModuleName(moduleName, containingFile, redirectedReference);
    if (tsResolution.resolvedModule !== undefined) {
        const resolvedFileName = path.normalize(tsResolution.resolvedModule.resolvedFileName);
        const tsResolutionResult = Object.assign(Object.assign({}, tsResolution.resolvedModule), { originalFileName: resolvedFileName, resolvedFileName });
        return resolutionResult === undefined ||
            resolutionResult.resolvedFileName ===
                tsResolutionResult.resolvedFileName ||
            isJsImplementationOfTypings(resolutionResult, tsResolutionResult)
            ? tsResolutionResult
            : resolutionResult;
    }
    return resolutionResult;
}
function makeResolveModuleName(compiler, compilerOptions, moduleResolutionHost, customResolveModuleName, instance) {
    if (customResolveModuleName === undefined) {
        if (!instance.moduleResolutionCache) {
            instance.moduleResolutionCache = createModuleResolutionCache(instance, moduleResolutionHost);
        }
        return (moduleName, containingFile, redirectedReference) => compiler.resolveModuleName(moduleName, containingFile, compilerOptions, moduleResolutionHost, instance.moduleResolutionCache, redirectedReference);
    }
    return (moduleName, containingFile) => customResolveModuleName(moduleName, containingFile, compilerOptions, moduleResolutionHost, compiler.resolveModuleName);
}
function addCache(host) {
    host.fileExists = createCache(host.fileExists, (host.fileExistsCache = new Map()));
    host.directoryExists = createCache(host.directoryExists, (host.directoryExistsCache = new Map()));
    host.realpath =
        host.realpath &&
            createCache(host.realpath, (host.realpathCache = new Map()));
    host.clearCache = clearCache;
    function createCache(originalFunction, cache) {
        return function getCached(arg) {
            let res = cache.get(arg);
            if (res !== undefined) {
                return res;
            }
            res = originalFunction(arg);
            cache.set(arg, res);
            return res;
        };
    }
    function clearCache() {
        var _a, _b, _c;
        (_a = host.fileExistsCache) === null || _a === void 0 ? void 0 : _a.clear();
        (_b = host.directoryExistsCache) === null || _b === void 0 ? void 0 : _b.clear();
        (_c = host.realpathCache) === null || _c === void 0 ? void 0 : _c.clear();
    }
}
//# sourceMappingURL=servicesHost.js.map