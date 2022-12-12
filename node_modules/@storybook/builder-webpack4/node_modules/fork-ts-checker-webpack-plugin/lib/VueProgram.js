"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (Object.hasOwnProperty.call(mod, k)) result[k] = mod[k];
    result["default"] = mod;
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
var fs = __importStar(require("fs"));
var path = __importStar(require("path"));
var resolution_1 = require("./resolution");
var VueProgram = /** @class */ (function () {
    function VueProgram() {
    }
    VueProgram.loadProgramConfig = function (typescript, configFile, compilerOptions) {
        var extraExtensions = ['vue'];
        var parseConfigHost = {
            fileExists: typescript.sys.fileExists,
            readFile: typescript.sys.readFile,
            useCaseSensitiveFileNames: typescript.sys.useCaseSensitiveFileNames,
            readDirectory: function (rootDir, extensions, excludes, includes, depth) {
                return typescript.sys.readDirectory(rootDir, extensions.concat(extraExtensions), excludes, includes, depth);
            }
        };
        var tsconfig = typescript.readConfigFile(configFile, typescript.sys.readFile).config;
        tsconfig.compilerOptions = tsconfig.compilerOptions || {};
        tsconfig.compilerOptions = __assign({}, tsconfig.compilerOptions, compilerOptions);
        var parsed = typescript.parseJsonConfigFileContent(tsconfig, parseConfigHost, path.dirname(configFile));
        parsed.options.allowNonTsExtensions = true;
        return parsed;
    };
    /**
     * Search for default wildcard or wildcard from options, we only search for that in tsconfig CompilerOptions.paths.
     * The path is resolved with thie given substitution and includes the CompilerOptions.baseUrl (if given).
     * If no paths given in tsconfig, then the default substitution is '[tsconfig directory]/src'.
     * (This is a fast, simplified inspiration of what's described here: https://github.com/Microsoft/TypeScript/issues/5039)
     */
    VueProgram.resolveNonTsModuleName = function (moduleName, containingFile, basedir, options) {
        var baseUrl = options.baseUrl ? options.baseUrl : basedir;
        var discardedSymbols = ['.', '..', '/'];
        var wildcards = [];
        if (options.paths) {
            Object.keys(options.paths).forEach(function (key) {
                var pathSymbol = key[0];
                if (discardedSymbols.indexOf(pathSymbol) < 0 &&
                    wildcards.indexOf(pathSymbol) < 0) {
                    wildcards.push(pathSymbol);
                }
            });
        }
        else {
            wildcards.push('@');
        }
        var isRelative = !path.isAbsolute(moduleName);
        var correctWildcard;
        wildcards.forEach(function (wildcard) {
            if (moduleName.substr(0, 2) === wildcard + "/") {
                correctWildcard = wildcard;
            }
        });
        if (correctWildcard) {
            var pattern = options.paths
                ? options.paths[correctWildcard + "/*"]
                : undefined;
            var substitution = pattern
                ? // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
                    options.paths[correctWildcard + "/*"][0].replace('*', '')
                : 'src';
            moduleName = path.resolve(baseUrl, substitution, moduleName.substr(2));
        }
        else if (isRelative) {
            moduleName = path.resolve(path.dirname(containingFile), moduleName);
        }
        return moduleName;
    };
    VueProgram.isVue = function (filePath) {
        return path.extname(filePath) === '.vue';
    };
    VueProgram.createProgram = function (typescript, programConfig, basedir, files, oldProgram, userResolveModuleName, userResolveTypeReferenceDirective, vueOptions) {
        var host = typescript.createCompilerHost(programConfig.options);
        var realGetSourceFile = host.getSourceFile;
        var _a = resolution_1.makeResolutionFunctions(userResolveModuleName, userResolveTypeReferenceDirective), resolveModuleName = _a.resolveModuleName, resolveTypeReferenceDirective = _a.resolveTypeReferenceDirective;
        host.resolveModuleNames = function (moduleNames, containingFile) {
            return moduleNames.map(function (moduleName) {
                return resolveModuleName(typescript, moduleName, containingFile, programConfig.options, host).resolvedModule;
            });
        };
        host.resolveTypeReferenceDirectives = function (typeDirectiveNames, containingFile) {
            return typeDirectiveNames.map(function (typeDirectiveName) {
                return resolveTypeReferenceDirective(typescript, typeDirectiveName, containingFile, programConfig.options, host).resolvedTypeReferenceDirective;
            });
        };
        // We need a host that can parse Vue SFCs (single file components).
        host.getSourceFile = function (filePath, languageVersion, onError) {
            try {
                var stats = fs.statSync(filePath);
                files.setMtime(filePath, stats.mtime.valueOf());
            }
            catch (e) {
                // probably file does not exists
                files.remove(filePath);
            }
            // get source file only if there is no source in files register
            if (!files.has(filePath) || !files.getData(filePath).source) {
                files.mutateData(filePath, function (data) {
                    data.source = realGetSourceFile(filePath, languageVersion, onError);
                });
            }
            var source = files.getData(filePath).source;
            // get typescript contents from Vue file
            if (source && VueProgram.isVue(filePath)) {
                var resolved = VueProgram.resolveScriptBlock(typescript, source.text, vueOptions.compiler);
                source = typescript.createSourceFile(filePath, resolved.content, languageVersion, true, resolved.scriptKind);
            }
            return source;
        };
        // We need a host with special module resolution for Vue files.
        host.resolveModuleNames = function (moduleNames, containingFile) {
            var resolvedModules = [];
            for (var _i = 0, moduleNames_1 = moduleNames; _i < moduleNames_1.length; _i++) {
                var moduleName = moduleNames_1[_i];
                // Try to use standard resolution.
                var resolvedModule = typescript.resolveModuleName(moduleName, containingFile, programConfig.options, {
                    fileExists: function (fileName) {
                        if (fileName.endsWith('.vue.ts')) {
                            return (host.fileExists(fileName.slice(0, -3)) ||
                                host.fileExists(fileName));
                        }
                        else {
                            return host.fileExists(fileName);
                        }
                    },
                    readFile: function (fileName) {
                        // This implementation is not necessary. Just for consistent behavior.
                        if (fileName.endsWith('.vue.ts') && !host.fileExists(fileName)) {
                            return host.readFile(fileName.slice(0, -3));
                        }
                        else {
                            return host.readFile(fileName);
                        }
                    }
                }).resolvedModule;
                if (resolvedModule) {
                    if (resolvedModule.resolvedFileName.endsWith('.vue.ts') &&
                        !host.fileExists(resolvedModule.resolvedFileName)) {
                        resolvedModule.resolvedFileName = resolvedModule.resolvedFileName.slice(0, -3);
                    }
                    resolvedModules.push(resolvedModule);
                }
                else {
                    // For non-ts extensions.
                    var absolutePath = VueProgram.resolveNonTsModuleName(moduleName, containingFile, basedir, programConfig.options);
                    if (VueProgram.isVue(moduleName)) {
                        resolvedModules.push({
                            resolvedFileName: absolutePath,
                            extension: '.ts'
                        });
                    }
                    else {
                        resolvedModules.push({
                            // If the file does exist, return an empty string (because we assume user has provided a ".d.ts" file for it).
                            resolvedFileName: host.fileExists(absolutePath)
                                ? ''
                                : absolutePath,
                            extension: '.ts'
                        });
                    }
                }
            }
            return resolvedModules;
        };
        return typescript.createProgram(programConfig.fileNames, programConfig.options, host, oldProgram // re-use old program
        );
    };
    VueProgram.getScriptKindByLang = function (typescript, lang) {
        if (lang === 'ts') {
            return typescript.ScriptKind.TS;
        }
        else if (lang === 'tsx') {
            return typescript.ScriptKind.TSX;
        }
        else if (lang === 'jsx') {
            return typescript.ScriptKind.JSX;
        }
        else {
            // when lang is "js" or no lang specified
            return typescript.ScriptKind.JS;
        }
    };
    VueProgram.resolveScriptBlock = function (typescript, content, compiler) {
        // We need to import template compiler for vue lazily because it cannot be included it
        // as direct dependency because it is an optional dependency of fork-ts-checker-webpack-plugin.
        // Since its version must not mismatch with user-installed Vue.js,
        // we should let the users install template compiler for vue by themselves.
        var parser;
        try {
            parser = require(compiler);
        }
        catch (err) {
            throw new Error('When you use `vue` option, make sure to install `' + compiler + '`.');
        }
        var script = parser.parseComponent(content, {
            pad: 'space'
        }).script;
        // No <script> block
        if (!script) {
            return {
                scriptKind: typescript.ScriptKind.JS,
                content: 'export default {};\n'
            };
        }
        var scriptKind = VueProgram.getScriptKindByLang(typescript, script.lang);
        // There is src attribute
        if (script.attrs.src) {
            // import path cannot be end with '.ts[x]'
            var src = script.attrs.src.replace(/\.tsx?$/i, '');
            return {
                scriptKind: scriptKind,
                // For now, ignore the error when the src file is not found
                // since it will produce incorrect code location.
                // It's not a large problem since it's handled on webpack side.
                content: '// @ts-ignore\n' +
                    ("export { default } from '" + src + "';\n") +
                    '// @ts-ignore\n' +
                    ("export * from '" + src + "';\n")
            };
        }
        // Pad blank lines to retain diagnostics location
        // We need to prepend `//` for each line to avoid
        // false positive of no-consecutive-blank-lines TSLint rule
        var offset = content.slice(0, script.start).split(/\r?\n/g).length;
        var paddedContent = Array(offset).join('//\n') + script.content.slice(script.start);
        return {
            scriptKind: scriptKind,
            content: paddedContent
        };
    };
    return VueProgram;
}());
exports.VueProgram = VueProgram;
//# sourceMappingURL=VueProgram.js.map