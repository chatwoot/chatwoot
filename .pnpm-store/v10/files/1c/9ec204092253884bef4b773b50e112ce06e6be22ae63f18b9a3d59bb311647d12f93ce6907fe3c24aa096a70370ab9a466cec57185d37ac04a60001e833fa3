import { join, relative } from 'node:path';
import yargs from 'yargs';
import { getCacheDir } from '../util/cache.js';
import { DeepPartial } from '../util/type-check.js';
import { VERSION } from './package.js';

export type ParsedCLIOptions = {
  patterns: string[];
  formatterName: string | undefined;
  quiet: boolean | undefined;
  useEslintrc: boolean | undefined;
  overrideConfigFile: string | undefined;
  extensions: string[] | undefined;
  rulePaths: string[] | undefined;
  ignorePath: string | undefined;
  cache: boolean | undefined;
  cacheLocation: string | undefined;
  resolvePluginsRelativeTo: string | undefined;
};

/** Default CLI Options */
export const cliOptionsDefaults = {
  formatterName: 'stylish',
  quiet: false,
  useEslintrc: true,
  cache: true,
  cacheLocation: relative(process.cwd(), join(getCacheDir(), '.eslintcache')),
} satisfies DeepPartial<ParsedCLIOptions>;

/** Parse CLI options */
export function parseArgv(argv: string[]): ParsedCLIOptions {
  const parsedArgv = yargs(argv.slice(2))
    .wrap(Math.min(140, process.stdout.columns))
    .scriptName('eslint-interactive')
    .version(VERSION)
    .usage('$0 [file.js] [dir]')
    .detectLocale(false)
    // NOTE: yargs doesn't support negative only option. So we use `--eslintrc` instead of `--no-eslintrc`.
    .option('eslintrc', {
      type: 'boolean',
      describe: 'Enable use of configuration from .eslintrc.*',
      default: cliOptionsDefaults.useEslintrc,
    })
    .option('config', {
      alias: 'c',
      type: 'string',
      describe: 'Use this configuration, overriding .eslintrc.* config options if present',
    })
    .option('ext', {
      type: 'array',
      describe: 'Specify JavaScript file extensions',
    })
    .nargs('ext', 1)
    .option('resolve-plugins-relative-to', {
      type: 'string',
      describe: 'A folder where plugins should be resolved from, CWD by default',
    })
    .option('rulesdir', {
      type: 'array',
      describe: 'Use additional rules from this directory',
    })
    .nargs('rulesdir', 1)
    // Following ESLint, --ignore-path accepts only one path. However, this limitation may be relaxed in the future.
    // ref: https://github.com/eslint/eslint/issues/9794
    .option('ignore-path', {
      type: 'string',
      describe: 'Specify path of ignore file',
    })
    .option('format', {
      type: 'string',
      describe: 'Specify the format to be used for the `Display problem messages` action',
      default: cliOptionsDefaults.formatterName,
    })
    .option('quiet', {
      type: 'boolean',
      describe: 'Report errors only',
      default: cliOptionsDefaults.quiet,
    })
    .option('cache', {
      type: 'boolean',
      describe: 'Only check changed files',
      default: cliOptionsDefaults.cache,
    })
    .option('cache-location', {
      type: 'string',
      describe: `Path to the cache file or directory`,
      default: cliOptionsDefaults.cacheLocation,
    })
    .example('$0 ./src', 'Lint ./src/ directory')
    .example('$0 ./src ./test', 'Lint multiple directories')
    .example("$0 './src/**/*.{ts,tsx,vue}'", 'Lint with glob pattern')
    .example('$0 ./src --ext .ts,.tsx,.vue', 'Lint with custom extensions')
    .example('$0 ./src --rulesdir ./rules', 'Lint with custom rules')
    .example('$0 ./src --no-eslintrc --config ./.eslintrc.ci.js', 'Lint with custom config')
    .parseSync();
  // NOTE: convert `string` type because yargs convert `'10'` (`string` type) into `10` (`number` type)
  // and `lintFiles` only accepts `string[]`.
  const patterns = parsedArgv._.map((pattern) => pattern.toString());
  const rulePaths = parsedArgv.rulesdir?.map((rulePath) => rulePath.toString());
  const extensions = parsedArgv.ext
    ?.map((extension) => extension.toString())
    // map '.js,.ts' into ['.js', '.ts']
    .flatMap((extension) => extension.split(','));
  const formatterName = parsedArgv.format;
  return {
    patterns,
    formatterName,
    quiet: parsedArgv.quiet,
    useEslintrc: parsedArgv.eslintrc,
    overrideConfigFile: parsedArgv.config,
    extensions,
    rulePaths,
    ignorePath: parsedArgv.ignorePath,
    cache: parsedArgv.cache,
    cacheLocation: parsedArgv['cache-location'],
    resolvePluginsRelativeTo: parsedArgv['resolve-plugins-relative-to'],
  };
}
