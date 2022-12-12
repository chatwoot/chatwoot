"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const path_1 = require("path");
function parseTypeScriptConfiguration(typescript, configFileName, configFileContext, configOverwriteJSON, parseConfigFileHost) {
    const parsedConfigFileJSON = typescript.readConfigFile(configFileName, parseConfigFileHost.readFile);
    const overwrittenConfigFileJSON = Object.assign(Object.assign(Object.assign({}, (parsedConfigFileJSON.config || {})), configOverwriteJSON), { compilerOptions: Object.assign(Object.assign({}, ((parsedConfigFileJSON.config || {}).compilerOptions || {})), (configOverwriteJSON.compilerOptions || {})) });
    const parsedConfigFile = typescript.parseJsonConfigFileContent(overwrittenConfigFileJSON, parseConfigFileHost, configFileContext);
    return Object.assign(Object.assign({}, parsedConfigFile), { options: Object.assign(Object.assign({}, parsedConfigFile.options), { configFilePath: configFileName }), errors: parsedConfigFileJSON.error ? [parsedConfigFileJSON.error] : parsedConfigFile.errors });
}
exports.parseTypeScriptConfiguration = parseTypeScriptConfiguration;
function getDependenciesFromTypeScriptConfiguration(typescript, parsedConfiguration, configFileContext, parseConfigFileHost, processedConfigFiles = []) {
    const files = new Set(parsedConfiguration.fileNames);
    if (typeof parsedConfiguration.options.configFilePath === 'string') {
        files.add(parsedConfiguration.options.configFilePath);
    }
    const dirs = new Set(Object.keys(parsedConfiguration.wildcardDirectories || {}));
    if (parsedConfiguration.projectReferences) {
        parsedConfiguration.projectReferences.forEach((projectReference) => {
            const configFile = typescript.resolveProjectReferencePath(projectReference);
            if (processedConfigFiles.includes(configFile)) {
                // handle circular dependencies
                return;
            }
            const parsedConfiguration = parseTypeScriptConfiguration(typescript, configFile, configFileContext, {}, parseConfigFileHost);
            const childDependencies = getDependenciesFromTypeScriptConfiguration(typescript, parsedConfiguration, configFileContext, parseConfigFileHost, [...processedConfigFiles, configFile]);
            childDependencies.files.forEach((file) => {
                files.add(file);
            });
            childDependencies.dirs.forEach((dir) => {
                dirs.add(dir);
            });
        });
    }
    const extensions = [
        typescript.Extension.Ts,
        typescript.Extension.Tsx,
        typescript.Extension.Js,
        typescript.Extension.Jsx,
        typescript.Extension.TsBuildInfo,
    ];
    return {
        files: Array.from(files).map((file) => path_1.normalize(file)),
        dirs: Array.from(dirs).map((dir) => path_1.normalize(dir)),
        extensions: extensions,
    };
}
exports.getDependenciesFromTypeScriptConfiguration = getDependenciesFromTypeScriptConfiguration;
