import { cliOptionsDefaults } from './cli/parse-argv.js';
export function translateCLIOptions(options, eslintOptionsType) {
    if (eslintOptionsType === 'eslintrc') {
        return {
            patterns: options.patterns,
            formatterName: options.formatterName,
            quiet: options.quiet,
            eslintOptions: {
                type: 'eslintrc',
                useEslintrc: options.useEslintrc,
                overrideConfigFile: options.overrideConfigFile,
                extensions: options.extensions,
                rulePaths: options.rulePaths,
                ignorePath: options.ignorePath,
                cache: options.cache,
                cacheLocation: options.cacheLocation,
                resolvePluginsRelativeTo: options.resolvePluginsRelativeTo,
            },
        };
    }
    else if (eslintOptionsType === 'flat') {
        return {
            patterns: options.patterns,
            formatterName: options.formatterName,
            quiet: options.quiet,
            eslintOptions: {
                type: 'flat',
                overrideConfigFile: options.overrideConfigFile,
                cache: options.cache,
                cacheLocation: options.cacheLocation,
            },
        };
    }
    else {
        throw new Error(`Unexpected configType: ${String(eslintOptionsType)}`);
    }
}
/** Default config of `Core` */
export const configDefaults = {
    formatterName: cliOptionsDefaults.formatterName,
    quiet: cliOptionsDefaults.quiet,
    cwd: process.cwd(),
    eslintOptions: {
        useEslintrc: cliOptionsDefaults.useEslintrc,
        overrideConfigFile: undefined,
        extensions: undefined,
        rulePaths: undefined,
        ignorePath: undefined,
        cache: cliOptionsDefaults.cache,
        cacheLocation: cliOptionsDefaults.cacheLocation,
        overrideConfig: undefined,
        resolvePluginsRelativeTo: undefined,
    },
};
export function normalizeConfig(config) {
    const cwd = config.cwd ?? configDefaults.cwd;
    let eslintOptions;
    if (config.eslintOptions.type === 'eslintrc') {
        eslintOptions = {
            type: 'eslintrc',
            useEslintrc: config.eslintOptions.useEslintrc ?? configDefaults.eslintOptions.useEslintrc,
            overrideConfigFile: config.eslintOptions.overrideConfigFile ?? configDefaults.eslintOptions.overrideConfigFile,
            extensions: config.eslintOptions.extensions ?? configDefaults.eslintOptions.extensions,
            rulePaths: config.eslintOptions.rulePaths ?? configDefaults.eslintOptions.rulePaths,
            ignorePath: config.eslintOptions.ignorePath ?? configDefaults.eslintOptions.ignorePath,
            cache: config.eslintOptions.cache ?? configDefaults.eslintOptions.cache,
            cacheLocation: config.eslintOptions.cacheLocation ?? configDefaults.eslintOptions.cacheLocation,
            overrideConfig: config.eslintOptions.overrideConfig ?? configDefaults.eslintOptions.overrideConfig,
            cwd,
            resolvePluginsRelativeTo: config.eslintOptions.resolvePluginsRelativeTo ?? configDefaults.eslintOptions.resolvePluginsRelativeTo,
            plugins: config.eslintOptions.plugins,
        };
    }
    else {
        eslintOptions = {
            type: 'flat',
            overrideConfigFile: config.eslintOptions.overrideConfigFile ?? configDefaults.eslintOptions.overrideConfigFile,
            cache: config.eslintOptions.cache ?? configDefaults.eslintOptions.cache,
            cacheLocation: config.eslintOptions.cacheLocation ?? configDefaults.eslintOptions.cacheLocation,
            overrideConfig: config.eslintOptions.overrideConfig ?? configDefaults.eslintOptions.overrideConfig,
            cwd,
        };
    }
    return {
        patterns: config.patterns,
        formatterName: config.formatterName ?? configDefaults.formatterName,
        quiet: config.quiet ?? configDefaults.quiet,
        cwd,
        eslintOptions,
    };
}
//# sourceMappingURL=config.js.map