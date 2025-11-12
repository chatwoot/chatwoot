import { ESLint } from 'eslint';
import { cliOptionsDefaults, ParsedCLIOptions } from './cli/parse-argv.js';
import { FlatESLint } from './eslint/use-at-your-own-risk.js';
import { DeepPartial } from './util/type-check.js';
type LegacyESLintOptions = { type: 'eslintrc' } & Pick<
  ESLint.Options,
  | 'useEslintrc'
  | 'overrideConfigFile'
  | 'extensions'
  | 'rulePaths'
  | 'ignorePath'
  | 'cache'
  | 'cacheLocation'
  | 'overrideConfig'
  | 'cwd'
  | 'resolvePluginsRelativeTo'
  | 'plugins'
>;
type FlatESLintOptions = { type: 'flat' } & Pick<
  FlatESLint.Options,
  'overrideConfigFile' | 'cache' | 'cacheLocation' | 'overrideConfig' | 'cwd'
>;

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

export function translateCLIOptions(options: ParsedCLIOptions, eslintOptionsType: ESLintOptionsType): Config {
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
  } else if (eslintOptionsType === 'flat') {
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
  } else {
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
} satisfies DeepPartial<Config>;

export type NormalizedConfig = {
  patterns: string[];
  formatterName: string;
  quiet: boolean;
  cwd: string;
  eslintOptions: ESLintOptions;
};

export function normalizeConfig(config: Config): NormalizedConfig {
  const cwd = config.cwd ?? configDefaults.cwd;
  let eslintOptions: NormalizedConfig['eslintOptions'];
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
      resolvePluginsRelativeTo:
        config.eslintOptions.resolvePluginsRelativeTo ?? configDefaults.eslintOptions.resolvePluginsRelativeTo,
      plugins: config.eslintOptions.plugins,
    };
  } else {
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
