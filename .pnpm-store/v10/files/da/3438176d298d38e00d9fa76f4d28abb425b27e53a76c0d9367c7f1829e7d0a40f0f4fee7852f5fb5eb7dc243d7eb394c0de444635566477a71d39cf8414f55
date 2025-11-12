import { ESLint } from 'eslint';
import { ParsedCLIOptions } from './cli/parse-argv.js';
import { FlatESLint } from './eslint/use-at-your-own-risk.js';
type LegacyESLintOptions = {
    type: 'eslintrc';
} & Pick<ESLint.Options, 'useEslintrc' | 'overrideConfigFile' | 'extensions' | 'rulePaths' | 'ignorePath' | 'cache' | 'cacheLocation' | 'overrideConfig' | 'cwd' | 'resolvePluginsRelativeTo' | 'plugins'>;
type FlatESLintOptions = {
    type: 'flat';
} & Pick<FlatESLint.Options, 'overrideConfigFile' | 'cache' | 'cacheLocation' | 'overrideConfig' | 'cwd'>;
export type ESLintOptions = LegacyESLintOptions | FlatESLintOptions;
/** The config of eslint-interactive */
export type Config = {
    patterns: string[];
    formatterName?: string | undefined;
    quiet?: boolean | undefined;
    cwd?: string | undefined;
    eslintOptions: ESLintOptions;
};
type ESLintOptionsType = 'eslintrc' | 'flat';
export declare function translateCLIOptions(options: ParsedCLIOptions, eslintOptionsType: ESLintOptionsType): Config;
/** Default config of `Core` */
export declare const configDefaults: {
    formatterName: string;
    quiet: false;
    cwd: string;
    eslintOptions: {
        useEslintrc: true;
        overrideConfigFile: undefined;
        extensions: undefined;
        rulePaths: undefined;
        ignorePath: undefined;
        cache: true;
        cacheLocation: string;
        overrideConfig: undefined;
        resolvePluginsRelativeTo: undefined;
    };
};
export type NormalizedConfig = {
    patterns: string[];
    formatterName: string;
    quiet: boolean;
    cwd: string;
    eslintOptions: ESLintOptions;
};
export declare function normalizeConfig(config: Config): NormalizedConfig;
export {};
//# sourceMappingURL=config.d.ts.map