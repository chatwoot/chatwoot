"use strict";
const crypto = require("crypto");
const loaderUtils = require("loader-utils");
const path = require("path");
const constants = require("./constants");
const instances_1 = require("./instances");
const utils_1 = require("./utils");
const loaderOptionsCache = {};
/**
 * The entry point for ts-loader
 */
function loader(contents) {
    this.cacheable && this.cacheable();
    const callback = this.async();
    const options = getLoaderOptions(this);
    const instanceOrError = instances_1.getTypeScriptInstance(options, this);
    if (instanceOrError.error !== undefined) {
        callback(new Error(instanceOrError.error.message));
        return;
    }
    const instance = instanceOrError.instance;
    instances_1.buildSolutionReferences(instance, this);
    successLoader(this, contents, callback, instance);
}
function successLoader(loaderContext, contents, callback, instance) {
    instances_1.initializeInstance(loaderContext, instance);
    instances_1.reportTranspileErrors(instance, loaderContext);
    const rawFilePath = path.normalize(loaderContext.resourcePath);
    const filePath = instance.loaderOptions.appendTsSuffixTo.length > 0 ||
        instance.loaderOptions.appendTsxSuffixTo.length > 0
        ? utils_1.appendSuffixesIfMatch({
            '.ts': instance.loaderOptions.appendTsSuffixTo,
            '.tsx': instance.loaderOptions.appendTsxSuffixTo,
        }, rawFilePath)
        : rawFilePath;
    const fileVersion = updateFileInCache(instance.loaderOptions, filePath, contents, instance);
    const { outputText, sourceMapText } = instance.loaderOptions.transpileOnly
        ? getTranspilationEmit(filePath, contents, instance, loaderContext)
        : getEmit(rawFilePath, filePath, instance, loaderContext);
    makeSourceMapAndFinish(sourceMapText, outputText, filePath, contents, loaderContext, fileVersion, callback, instance);
}
function makeSourceMapAndFinish(sourceMapText, outputText, filePath, contents, loaderContext, fileVersion, callback, instance) {
    if (outputText === null || outputText === undefined) {
        setModuleMeta(loaderContext, instance, fileVersion);
        const additionalGuidance = utils_1.isReferencedFile(instance, filePath)
            ? ' The most common cause for this is having errors when building referenced projects.'
            : !instance.loaderOptions.allowTsInNodeModules &&
                filePath.indexOf('node_modules') !== -1
                ? ' By default, ts-loader will not compile .ts files in node_modules.\n' +
                    'You should not need to recompile .ts files there, but if you really want to, use the allowTsInNodeModules option.\n' +
                    'See: https://github.com/Microsoft/TypeScript/issues/12358'
                : '';
        callback(new Error(`TypeScript emitted no output for ${filePath}.${additionalGuidance}`), outputText, undefined);
        return;
    }
    const { sourceMap, output } = makeSourceMap(sourceMapText, outputText, filePath, contents, loaderContext);
    setModuleMeta(loaderContext, instance, fileVersion);
    callback(null, output, sourceMap);
}
function setModuleMeta(loaderContext, instance, fileVersion) {
    // _module.meta is not available inside happypack
    if (!instance.loaderOptions.happyPackMode &&
        loaderContext._module.buildMeta !== undefined) {
        // Make sure webpack is aware that even though the emitted JavaScript may be the same as
        // a previously cached version the TypeScript may be different and therefore should be
        // treated as new
        loaderContext._module.buildMeta.tsLoaderFileVersion = fileVersion;
    }
}
/**
 * Get a unique hash based on the contents of the options
 * Hash is created from the values converted to strings
 * Values which are functions (such as getCustomTransformers) are
 * converted to strings by this code, which JSON.stringify would not do.
 */
function getOptionsHash(loaderOptions) {
    const hash = crypto.createHash('sha256');
    Object.keys(loaderOptions).forEach(key => {
        const value = loaderOptions[key];
        if (value) {
            hash.update(key + value.toString());
        }
    });
    return hash.digest('hex').substring(0, 16);
}
/**
 * either retrieves loader options from the cache
 * or creates them, adds them to the cache and returns
 */
function getLoaderOptions(loaderContext) {
    const loaderOptions = loaderUtils.getOptions(loaderContext) ||
        {};
    // If no instance name is given in the options, use the hash of the loader options
    // In this way, if different options are given the instances will be different
    const instanceName = loaderOptions.instance || 'default_' + getOptionsHash(loaderOptions);
    if (!loaderOptionsCache.hasOwnProperty(instanceName)) {
        loaderOptionsCache[instanceName] = new WeakMap();
    }
    const cache = loaderOptionsCache[instanceName];
    if (cache.has(loaderOptions)) {
        return cache.get(loaderOptions);
    }
    validateLoaderOptions(loaderOptions);
    const options = makeLoaderOptions(instanceName, loaderOptions);
    cache.set(loaderOptions, options);
    return options;
}
const validLoaderOptions = [
    'silent',
    'logLevel',
    'logInfoToStdOut',
    'instance',
    'compiler',
    'context',
    'configFile',
    'transpileOnly',
    'ignoreDiagnostics',
    'errorFormatter',
    'colors',
    'compilerOptions',
    'appendTsSuffixTo',
    'appendTsxSuffixTo',
    'onlyCompileBundledFiles',
    'happyPackMode',
    'getCustomTransformers',
    'reportFiles',
    'experimentalWatchApi',
    'allowTsInNodeModules',
    'experimentalFileCaching',
    'projectReferences',
    'resolveModuleName',
    'resolveTypeReferenceDirective',
    'useCaseSensitiveFileNames',
];
/**
 * Validate the supplied loader options.
 * At present this validates the option names only; in future we may look at validating the values too
 * @param loaderOptions
 */
function validateLoaderOptions(loaderOptions) {
    const loaderOptionKeys = Object.keys(loaderOptions);
    for (let i = 0; i < loaderOptionKeys.length; i++) {
        const option = loaderOptionKeys[i];
        const isUnexpectedOption = validLoaderOptions.indexOf(option) === -1;
        if (isUnexpectedOption) {
            throw new Error(`ts-loader was supplied with an unexpected loader option: ${option}

Please take a look at the options you are supplying; the following are valid options:
${validLoaderOptions.join(' / ')}
`);
        }
    }
    if (loaderOptions.context !== undefined &&
        !path.isAbsolute(loaderOptions.context)) {
        throw new Error(`Option 'context' has to be an absolute path. Given '${loaderOptions.context}'.`);
    }
}
function makeLoaderOptions(instanceName, loaderOptions) {
    const options = Object.assign({}, {
        silent: false,
        logLevel: 'WARN',
        logInfoToStdOut: false,
        compiler: 'typescript',
        configFile: 'tsconfig.json',
        context: undefined,
        transpileOnly: false,
        compilerOptions: {},
        appendTsSuffixTo: [],
        appendTsxSuffixTo: [],
        transformers: {},
        happyPackMode: false,
        colors: true,
        onlyCompileBundledFiles: false,
        reportFiles: [],
        // When the watch API usage stabilises look to remove this option and make watch usage the default behaviour when available
        experimentalWatchApi: false,
        allowTsInNodeModules: false,
        experimentalFileCaching: true,
    }, loaderOptions);
    options.ignoreDiagnostics = utils_1.arrify(options.ignoreDiagnostics).map(Number);
    options.logLevel = options.logLevel.toUpperCase();
    options.instance = instanceName;
    // happypack can be used only together with transpileOnly mode
    options.transpileOnly = options.happyPackMode ? true : options.transpileOnly;
    return options;
}
/**
 * Either add file to the overall files cache or update it in the cache when the file contents have changed
 * Also add the file to the modified files
 */
function updateFileInCache(options, filePath, contents, instance) {
    let fileWatcherEventKind;
    // Update file contents
    const key = instance.filePathKeyMapper(filePath);
    let file = instance.files.get(key);
    if (file === undefined) {
        file = instance.otherFiles.get(key);
        if (file !== undefined) {
            if (!utils_1.isReferencedFile(instance, filePath)) {
                instance.otherFiles.delete(key);
                instance.files.set(key, file);
                instance.changedFilesList = true;
            }
        }
        else {
            if (instance.watchHost !== undefined) {
                fileWatcherEventKind = instance.compiler.FileWatcherEventKind.Created;
            }
            file = { fileName: filePath, version: 0 };
            if (!utils_1.isReferencedFile(instance, filePath)) {
                instance.files.set(key, file);
                instance.changedFilesList = true;
            }
        }
    }
    if (instance.watchHost !== undefined && contents === undefined) {
        fileWatcherEventKind = instance.compiler.FileWatcherEventKind.Deleted;
    }
    // filePath is a root file as it was passed to the loader. But it
    // could have been found earlier as a dependency of another file. If
    // that is the case, compiling this file changes the structure of
    // the program and we need to increase the instance version.
    //
    // See https://github.com/TypeStrong/ts-loader/issues/943
    if (!utils_1.isReferencedFile(instance, filePath) &&
        !instance.rootFileNames.has(filePath) &&
        // however, be careful not to add files from node_modules unless
        // it is allowed by the options.
        (options.allowTsInNodeModules || filePath.indexOf('node_modules') === -1)) {
        instance.version++;
        instance.rootFileNames.add(filePath);
    }
    if (file.text !== contents) {
        file.version++;
        file.text = contents;
        file.modifiedTime = new Date();
        instance.version++;
        if (instance.watchHost !== undefined &&
            fileWatcherEventKind === undefined) {
            fileWatcherEventKind = instance.compiler.FileWatcherEventKind.Changed;
        }
    }
    // Added in case the files were already updated by the watch API
    if (instance.modifiedFiles && instance.modifiedFiles.get(key)) {
        fileWatcherEventKind = instance.compiler.FileWatcherEventKind.Changed;
    }
    if (instance.watchHost !== undefined && fileWatcherEventKind !== undefined) {
        instance.hasUnaccountedModifiedFiles =
            instance.watchHost.invokeFileWatcher(filePath, fileWatcherEventKind) ||
                instance.hasUnaccountedModifiedFiles;
    }
    // push this file to modified files hash.
    if (!instance.modifiedFiles) {
        instance.modifiedFiles = new Map();
    }
    instance.modifiedFiles.set(key, true);
    return file.version;
}
function getEmit(rawFilePath, filePath, instance, loaderContext) {
    var _a;
    const outputFiles = instances_1.getEmitOutput(instance, filePath);
    loaderContext.clearDependencies();
    loaderContext.addDependency(rawFilePath);
    const dependencies = [];
    const addDependency = (file) => {
        file = path.resolve(file);
        loaderContext.addDependency(file);
        dependencies.push(file);
    };
    // Make this file dependent on *all* definition files in the program
    if (!utils_1.isReferencedFile(instance, filePath)) {
        for (const { fileName: defFilePath } of instance.files.values()) {
            if (defFilePath.match(constants.dtsDtsxOrDtsDtsxMapRegex) &&
                // Remove the project reference d.ts as we are adding dependency for .ts later
                // This removed extra build pass (resulting in new stats object in initial build)
                !((_a = instance.solutionBuilderHost) === null || _a === void 0 ? void 0 : _a.getOutputFileKeyFromReferencedProject(defFilePath))) {
                addDependency(defFilePath);
            }
        }
    }
    // Additionally make this file dependent on all imported files
    const fileDependencies = instance.dependencyGraph.get(instance.filePathKeyMapper(filePath));
    if (fileDependencies) {
        for (const { resolvedFileName, originalFileName } of fileDependencies) {
            // In the case of dependencies that are part of a project reference,
            // the real dependency that webpack should watch is the JS output file.
            addDependency(instances_1.getInputFileNameFromOutput(instance, path.resolve(resolvedFileName)) ||
                originalFileName);
        }
    }
    addDependenciesFromSolutionBuilder(instance, filePath, addDependency);
    loaderContext._module.buildMeta.tsLoaderDefinitionFileVersions = dependencies.map(defFilePath => path.relative(loaderContext.rootContext, defFilePath) +
        '@' +
        (utils_1.isReferencedFile(instance, defFilePath)
            ? instance
                .solutionBuilderHost.getInputFileStamp(defFilePath)
                .toString()
            : (instance.files.get(instance.filePathKeyMapper(defFilePath)) ||
                instance.otherFiles.get(instance.filePathKeyMapper(defFilePath)) || {
                version: '?',
            }).version));
    return getOutputAndSourceMapFromOutputFiles(outputFiles);
}
function getOutputAndSourceMapFromOutputFiles(outputFiles) {
    const outputFile = outputFiles
        .filter(file => file.name.match(constants.jsJsx))
        .pop();
    const outputText = outputFile === undefined ? undefined : outputFile.text;
    const sourceMapFile = outputFiles
        .filter(file => file.name.match(constants.jsJsxMap))
        .pop();
    const sourceMapText = sourceMapFile === undefined ? undefined : sourceMapFile.text;
    return { outputText, sourceMapText };
}
function addDependenciesFromSolutionBuilder(instance, filePath, addDependency) {
    if (!instance.solutionBuilderHost) {
        return;
    }
    // Add all the input files from the references as
    const resolvedFilePath = instance.filePathKeyMapper(filePath);
    if (!utils_1.isReferencedFile(instance, filePath)) {
        if (instance.configParseResult.fileNames.some(f => instance.filePathKeyMapper(f) === resolvedFilePath)) {
            addDependenciesFromProjectReferences(instance, instance.configFilePath, instance.configParseResult.projectReferences, addDependency);
        }
        return;
    }
    // Referenced file find the config for it
    for (const [configFile, configInfo,] of instance.solutionBuilderHost.configFileInfo.entries()) {
        if (!configInfo.config ||
            !configInfo.config.projectReferences ||
            !configInfo.config.projectReferences.length) {
            continue;
        }
        if (configInfo.outputFileNames) {
            if (!configInfo.outputFileNames.has(resolvedFilePath)) {
                continue;
            }
        }
        else if (!configInfo.config.fileNames.some(f => instance.filePathKeyMapper(f) === resolvedFilePath)) {
            continue;
        }
        // Depend on all the dts files from the program
        if (configInfo.dtsFiles) {
            configInfo.dtsFiles.forEach(addDependency);
        }
        addDependenciesFromProjectReferences(instance, configFile, configInfo.config.projectReferences, addDependency);
        break;
    }
}
function addDependenciesFromProjectReferences(instance, configFile, projectReferences, addDependency) {
    if (!projectReferences || !projectReferences.length) {
        return;
    }
    // This is the config for the input file
    const seenMap = new Map();
    seenMap.set(instance.filePathKeyMapper(configFile), true);
    // Add dependencies to all the input files from the project reference files since building them
    const queue = projectReferences.slice();
    while (true) {
        const currentRef = queue.pop();
        if (!currentRef) {
            break;
        }
        const refConfigFile = instance.filePathKeyMapper(instance.compiler.resolveProjectReferencePath(currentRef));
        if (seenMap.has(refConfigFile)) {
            continue;
        }
        const refConfigInfo = instance.solutionBuilderHost.configFileInfo.get(refConfigFile);
        if (!refConfigInfo) {
            continue;
        }
        seenMap.set(refConfigFile, true);
        if (refConfigInfo.config) {
            refConfigInfo.config.fileNames.forEach(addDependency);
            if (refConfigInfo.config.projectReferences) {
                queue.push(...refConfigInfo.config.projectReferences);
            }
        }
    }
}
/**
 * Transpile file
 */
function getTranspilationEmit(fileName, contents, instance, loaderContext) {
    if (utils_1.isReferencedFile(instance, fileName)) {
        const outputFiles = instance.solutionBuilderHost.getOutputFilesFromReferencedProjectInput(fileName);
        addDependenciesFromSolutionBuilder(instance, fileName, file => loaderContext.addDependency(path.resolve(file)));
        return getOutputAndSourceMapFromOutputFiles(outputFiles);
    }
    const { outputText, sourceMapText, diagnostics, } = instance.compiler.transpileModule(contents, {
        compilerOptions: Object.assign(Object.assign({}, instance.compilerOptions), { rootDir: undefined }),
        transformers: instance.transformers,
        reportDiagnostics: true,
        fileName,
    });
    const module = loaderContext._module;
    addDependenciesFromSolutionBuilder(instance, fileName, file => loaderContext.addDependency(path.resolve(file)));
    // _module.errors is not available inside happypack - see https://github.com/TypeStrong/ts-loader/issues/336
    if (!instance.loaderOptions.happyPackMode) {
        const errors = utils_1.formatErrors(diagnostics, instance.loaderOptions, instance.colors, instance.compiler, { module }, loaderContext.context);
        /**
         * Since webpack 5, the `errors` property is deprecated,
         * so we can check if some methods for reporting errors exist.
         */
        if (module.addError) {
            errors.forEach(error => module.addError(error));
        }
        else {
            module.errors.push(...errors);
        }
    }
    return { outputText, sourceMapText };
}
function makeSourceMap(sourceMapText, outputText, filePath, contents, loaderContext) {
    if (sourceMapText === undefined) {
        return { output: outputText, sourceMap: undefined };
    }
    return {
        output: outputText.replace(/^\/\/# sourceMappingURL=[^\r\n]*/gm, ''),
        sourceMap: Object.assign(JSON.parse(sourceMapText), {
            sources: [loaderUtils.getRemainingRequest(loaderContext)],
            file: filePath,
            sourcesContent: [contents],
        }),
    };
}
module.exports = loader;
//# sourceMappingURL=index.js.map