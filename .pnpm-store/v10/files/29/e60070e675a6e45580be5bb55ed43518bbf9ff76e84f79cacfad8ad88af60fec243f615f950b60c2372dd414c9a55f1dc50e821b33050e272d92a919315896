/** @typedef {import('./index').Logger} Logger */

import debug from 'debug'
import { lilconfig } from 'lilconfig'
import YAML from 'yaml'

import { dynamicImport } from './dynamicImport.js'
import { resolveConfig } from './resolveConfig.js'

const debugLog = debug('lint-staged:loadConfig')

const PACKAGE_JSON = 'package.json'

/**
 * The list of files `lint-staged` will read configuration
 * from, in the declared order.
 */
export const searchPlaces = [
  PACKAGE_JSON,
  '.lintstagedrc',
  '.lintstagedrc.json',
  '.lintstagedrc.yaml',
  '.lintstagedrc.yml',
  '.lintstagedrc.mjs',
  '.lintstagedrc.js',
  '.lintstagedrc.cjs',
  'lint-staged.config.mjs',
  'lint-staged.config.js',
  'lint-staged.config.cjs',
]

const jsonParse = (path, content) => {
  try {
    return JSON.parse(content)
  } catch (error) {
    if (path.endsWith(PACKAGE_JSON)) {
      debugLog('Ignoring invalid package file `%s` with content:\n%s', path, content)
      return undefined
    }

    throw error
  }
}

const yamlParse = (path, content) => YAML.parse(content)

/**
 * `lilconfig` doesn't support yaml files by default,
 * so we add custom loaders for those. Files without
 * an extensions are assumed to be yaml — this
 * assumption is in `cosmiconfig` as well.
 */
const loaders = {
  '.js': dynamicImport,
  '.json': jsonParse,
  '.mjs': dynamicImport,
  '.cjs': dynamicImport,
  '.yaml': yamlParse,
  '.yml': yamlParse,
  noExt: yamlParse,
}

const explorer = lilconfig('lint-staged', { searchPlaces, loaders })

/**
 * @param {object} options
 * @param {string} [options.configPath] - Explicit path to a config file
 * @param {string} [options.cwd] - Current working directory
 */
export const loadConfig = async ({ configPath, cwd }, logger) => {
  try {
    if (configPath) {
      debugLog('Loading configuration from `%s`...', configPath)
    } else {
      debugLog('Searching for configuration from `%s`...', cwd)
    }

    const result = await (configPath
      ? explorer.load(resolveConfig(configPath))
      : explorer.search(cwd))

    if (!result) return {}

    // config is a promise when using the `dynamicImport` loader
    const config = await result.config
    const filepath = result.filepath

    debugLog('Successfully loaded config from `%s`:\n%O', filepath, config)

    return { config, filepath }
  } catch (error) {
    debugLog('Failed to load configuration!')
    logger.error(error)
    return {}
  }
}
