"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getCompilerOptions = exports.getCompiler = void 0;
const semver = require("semver");
function getCompiler(loaderOptions, log) {
    let compiler;
    let errorMessage;
    let compilerDetailsLogMessage;
    let compilerCompatible = false;
    try {
        compiler = require(loaderOptions.compiler);
    }
    catch (e) {
        errorMessage =
            loaderOptions.compiler === 'typescript'
                ? 'Could not load TypeScript. Try installing with `yarn add typescript` or `npm install typescript`. If TypeScript is installed globally, try using `yarn link typescript` or `npm link typescript`.'
                : `Could not load TypeScript compiler with NPM package name \`${loaderOptions.compiler}\`. Are you sure it is correctly installed?`;
    }
    if (errorMessage === undefined) {
        compilerDetailsLogMessage = `ts-loader: Using ${loaderOptions.compiler}@${compiler.version}`;
        compilerCompatible = false;
        if (loaderOptions.compiler === 'typescript') {
            if (compiler.version !== undefined &&
                semver.gte(compiler.version, '3.6.3')) {
                // don't log yet in this case, if a tsconfig.json exists we want to combine the message
                compilerCompatible = true;
            }
            else {
                log.logError(`${compilerDetailsLogMessage}. This version is incompatible with ts-loader. Please upgrade to the latest version of TypeScript.`);
            }
        }
        else {
            log.logWarning(`${compilerDetailsLogMessage}. This version may or may not be compatible with ts-loader.`);
        }
    }
    return {
        compiler,
        compilerCompatible,
        compilerDetailsLogMessage,
        errorMessage,
    };
}
exports.getCompiler = getCompiler;
function getCompilerOptions(configParseResult, compiler) {
    const compilerOptions = Object.assign({}, configParseResult.options, {
        skipLibCheck: true,
        suppressOutputPathCheck: true,
    });
    // if `module` is not specified and not using ES6+ target, default to CJS module output
    if (compilerOptions.module === undefined &&
        compilerOptions.target !== undefined &&
        compilerOptions.target < compiler.ScriptTarget.ES2015) {
        compilerOptions.module = compiler.ModuleKind.CommonJS;
    }
    if (configParseResult.options.configFile) {
        Object.defineProperty(compilerOptions, 'configFile', {
            enumerable: false,
            writable: false,
            value: configParseResult.options.configFile,
        });
    }
    return compilerOptions;
}
exports.getCompilerOptions = getCompilerOptions;
//# sourceMappingURL=compilerSetup.js.map