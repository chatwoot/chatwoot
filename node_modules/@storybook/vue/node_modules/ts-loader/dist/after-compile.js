"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.makeAfterCompile = void 0;
const path = require("path");
const constants = require("./constants");
const instances_1 = require("./instances");
const utils_1 = require("./utils");
/**
 * This returns a function that has options to add assets and also to provide errors to webpack
 * In webpack 4 we can do both during the afterCompile hook
 * In webpack 5 only errors should be provided during aftercompile.  Assets should be
 * emitted during the afterProcessAssets hook
 */
function makeAfterCompile(instance, configFilePath) {
    let getCompilerOptionDiagnostics = true;
    let checkAllFilesForErrors = true;
    return (compilation, callback) => {
        // Don't add errors for child compilations
        if (compilation.compiler.isChild()) {
            callback();
            return;
        }
        if (instance.loaderOptions.transpileOnly) {
            provideAssetsFromSolutionBuilderHost(instance, compilation);
            callback();
            return;
        }
        removeCompilationTSLoaderErrors(compilation, instance.loaderOptions);
        provideCompilerOptionDiagnosticErrorsToWebpack(getCompilerOptionDiagnostics, compilation, instance, configFilePath);
        getCompilerOptionDiagnostics = false;
        const modules = determineModules(compilation, instance);
        const filesToCheckForErrors = determineFilesToCheckForErrors(checkAllFilesForErrors, instance);
        checkAllFilesForErrors = false;
        const filesWithErrors = new Map();
        provideErrorsToWebpack(filesToCheckForErrors, filesWithErrors, compilation, modules, instance);
        provideSolutionErrorsToWebpack(compilation, modules, instance);
        provideDeclarationFilesToWebpack(filesToCheckForErrors, instance, compilation);
        provideTsBuildInfoFilesToWebpack(instance, compilation);
        provideAssetsFromSolutionBuilderHost(instance, compilation);
        instance.filesWithErrors = filesWithErrors;
        instance.modifiedFiles = undefined;
        instance.projectsMissingSourceMaps = new Set();
        callback();
    };
}
exports.makeAfterCompile = makeAfterCompile;
/**
 * handle compiler option errors after the first compile
 */
function provideCompilerOptionDiagnosticErrorsToWebpack(getCompilerOptionDiagnostics, compilation, instance, configFilePath) {
    if (getCompilerOptionDiagnostics) {
        const { languageService, loaderOptions, compiler, program } = instance;
        const errors = utils_1.formatErrors(program === undefined
            ? languageService.getCompilerOptionsDiagnostics()
            : program.getOptionsDiagnostics(), loaderOptions, instance.colors, compiler, { file: configFilePath || 'tsconfig.json' }, compilation.compiler.context);
        compilation.errors.push(...errors);
    }
}
/**
 * build map of all modules based on normalized filename
 * this is used for quick-lookup when trying to find modules
 * based on filepath
 */
function determineModules(compilation, { filePathKeyMapper }) {
    const modules = new Map();
    compilation.modules.forEach(module => {
        if (module.resource) {
            const modulePath = filePathKeyMapper(module.resource);
            const existingModules = modules.get(modulePath);
            if (existingModules !== undefined) {
                if (!existingModules.includes(module)) {
                    existingModules.push(module);
                }
            }
            else {
                modules.set(modulePath, [module]);
            }
        }
    });
    return modules;
}
function determineFilesToCheckForErrors(checkAllFilesForErrors, instance) {
    const { files, modifiedFiles, filesWithErrors, otherFiles } = instance;
    // calculate array of files to check
    const filesToCheckForErrors = new Map();
    if (checkAllFilesForErrors) {
        // check all files on initial run
        for (const [filePath, file] of files) {
            addFileToCheckForErrors(filePath, file);
        }
        for (const [filePath, file] of otherFiles) {
            addFileToCheckForErrors(filePath, file);
        }
    }
    else if (modifiedFiles !== null &&
        modifiedFiles !== undefined &&
        modifiedFiles.size) {
        const reverseDependencyGraph = utils_1.populateReverseDependencyGraph(instance);
        // check all modified files, and all dependants
        for (const modifiedFileName of modifiedFiles.keys()) {
            for (const fileName of utils_1.collectAllDependants(reverseDependencyGraph, modifiedFileName).keys()) {
                const fileToCheckForErrors = files.get(fileName) || otherFiles.get(fileName);
                addFileToCheckForErrors(fileName, fileToCheckForErrors);
            }
        }
    }
    // re-check files with errors from previous build
    if (filesWithErrors !== undefined) {
        for (const [fileWithErrorName, fileWithErrors] of filesWithErrors) {
            addFileToCheckForErrors(fileWithErrorName, fileWithErrors);
        }
    }
    return filesToCheckForErrors;
    function addFileToCheckForErrors(filePath, file) {
        if (!utils_1.isReferencedFile(instance, filePath)) {
            filesToCheckForErrors.set(filePath, file);
        }
    }
}
function provideErrorsToWebpack(filesToCheckForErrors, filesWithErrors, compilation, modules, instance) {
    const { compiler, files, loaderOptions, compilerOptions, otherFiles, } = instance;
    const filePathRegex = compilerOptions.allowJs === true
        ? constants.dtsTsTsxJsJsxRegex
        : constants.dtsTsTsxRegex;
    // I’m pretty sure this will never be undefined here
    const program = utils_1.ensureProgram(instance);
    for (const [filePath, { fileName }] of filesToCheckForErrors.entries()) {
        if (fileName.match(filePathRegex) === null) {
            continue;
        }
        const sourceFile = program && program.getSourceFile(fileName);
        const errors = [];
        if (program && sourceFile) {
            errors.push(...program.getSyntacticDiagnostics(sourceFile), ...program
                .getSemanticDiagnostics(sourceFile)
                // Output file has not been built from source file - this message is redundant with
                // program.getOptionsDiagnostics() separately added in instances.ts
                .filter(({ code }) => code !== 6305));
        }
        if (errors.length > 0) {
            const fileWithError = files.get(filePath) || otherFiles.get(filePath);
            filesWithErrors.set(filePath, fileWithError);
        }
        // if we have access to a webpack module, use that
        const associatedModules = modules.get(instance.filePathKeyMapper(fileName));
        if (associatedModules !== undefined) {
            associatedModules.forEach(module => {
                removeModuleTSLoaderError(module, loaderOptions);
                // append errors
                const formattedErrors = utils_1.formatErrors(errors, loaderOptions, instance.colors, compiler, { module }, compilation.compiler.context);
                formattedErrors.forEach(error => {
                    if (module.addError) {
                        module.addError(error);
                    }
                    else {
                        module.errors.push(error);
                    }
                });
                compilation.errors.push(...formattedErrors);
            });
        }
        else {
            // otherwise it's a more generic error
            const formattedErrors = utils_1.formatErrors(errors, loaderOptions, instance.colors, compiler, { file: fileName }, compilation.compiler.context);
            compilation.errors.push(...formattedErrors);
        }
    }
}
function provideSolutionErrorsToWebpack(compilation, modules, instance) {
    if (!instance.solutionBuilderHost ||
        !(instance.solutionBuilderHost.diagnostics.global.length ||
            instance.solutionBuilderHost.diagnostics.perFile.size)) {
        return;
    }
    const { compiler, loaderOptions, solutionBuilderHost: { diagnostics }, } = instance;
    for (const [filePath, perFileDiagnostics] of diagnostics.perFile) {
        // if we have access to a webpack module, use that
        const associatedModules = modules.get(filePath);
        if (associatedModules !== undefined) {
            associatedModules.forEach(module => {
                removeModuleTSLoaderError(module, loaderOptions);
                // append errors
                const formattedErrors = utils_1.formatErrors(perFileDiagnostics, loaderOptions, instance.colors, compiler, { module }, compilation.compiler.context);
                formattedErrors.forEach(error => {
                    if (module.addError) {
                        module.addError(error);
                    }
                    else {
                        module.errors.push(error);
                    }
                });
                compilation.errors.push(...formattedErrors);
            });
        }
        else {
            // otherwise it's a more generic error
            const formattedErrors = utils_1.formatErrors(perFileDiagnostics, loaderOptions, instance.colors, compiler, { file: path.resolve(perFileDiagnostics[0].file.fileName) }, compilation.compiler.context);
            compilation.errors.push(...formattedErrors);
        }
    }
    // Add global solution errors
    compilation.errors.push(...utils_1.formatErrors(diagnostics.global, instance.loaderOptions, instance.colors, instance.compiler, { file: 'tsconfig.json' }, compilation.compiler.context));
}
/**
 * gather all declaration files from TypeScript and output them to webpack
 */
function provideDeclarationFilesToWebpack(filesToCheckForErrors, instance, compilation) {
    for (const { fileName } of filesToCheckForErrors.values()) {
        if (fileName.match(constants.tsTsxRegex) === null) {
            continue;
        }
        addDeclarationFilesAsAsset(instances_1.getEmitOutput(instance, fileName), compilation);
    }
}
function addDeclarationFilesAsAsset(outputFiles, compilation, skipOutputFile) {
    outputFilesToAsset(outputFiles, compilation, outputFile => skipOutputFile && skipOutputFile(outputFile)
        ? true
        : !outputFile.name.match(constants.dtsDtsxOrDtsDtsxMapRegex));
}
function outputFileToAsset(outputFile, compilation) {
    const assetPath = path.relative(compilation.compiler.outputPath, outputFile.name);
    compilation.assets[assetPath] = {
        source: () => outputFile.text,
        size: () => outputFile.text.length,
    };
}
function outputFilesToAsset(outputFiles, compilation, skipOutputFile) {
    for (const outputFile of outputFiles) {
        if (!skipOutputFile || !skipOutputFile(outputFile)) {
            outputFileToAsset(outputFile, compilation);
        }
    }
}
/**
 * gather all .tsbuildinfo for the project
 */
function provideTsBuildInfoFilesToWebpack(instance, compilation) {
    if (instance.watchHost) {
        // Ensure emit is complete
        instances_1.getEmitFromWatchHost(instance);
        if (instance.watchHost.tsbuildinfo) {
            outputFileToAsset(instance.watchHost.tsbuildinfo, compilation);
        }
        instance.watchHost.outputFiles.clear();
        instance.watchHost.tsbuildinfo = undefined;
    }
}
/**
 * gather all solution builder assets
 */
function provideAssetsFromSolutionBuilderHost(instance, compilation) {
    if (instance.solutionBuilderHost) {
        // written files
        outputFilesToAsset(instance.solutionBuilderHost.writtenFiles, compilation);
        instance.solutionBuilderHost.writtenFiles.length = 0;
    }
}
/**
 * handle all other errors. The basic approach here to get accurate error
 * reporting is to start with a "blank slate" each compilation and gather
 * all errors from all files. Since webpack tracks errors in a module from
 * compilation-to-compilation, and since not every module always runs through
 * the loader, we need to detect and remove any pre-existing errors.
 */
function removeCompilationTSLoaderErrors(compilation, loaderOptions) {
    compilation.errors = compilation.errors.filter(error => error.loaderSource !== utils_1.tsLoaderSource(loaderOptions));
}
function removeModuleTSLoaderError(module, loaderOptions) {
    /**
     * Since webpack 5, the `errors` property is deprecated,
     * so we can check if some methods for reporting errors exist.
     */
    if (!!module.addError) {
        const warnings = module.getWarnings();
        const errors = module.getErrors();
        module.clearWarningsAndErrors();
        Array.from(warnings || []).forEach(warning => module.addWarning(warning));
        Array.from(errors || [])
            .filter((error) => error.loaderSource !== utils_1.tsLoaderSource(loaderOptions))
            .forEach(error => module.addError(error));
    }
    else {
        module.errors = module.errors.filter(error => error.loaderSource !== utils_1.tsLoaderSource(loaderOptions));
    }
}
//# sourceMappingURL=after-compile.js.map