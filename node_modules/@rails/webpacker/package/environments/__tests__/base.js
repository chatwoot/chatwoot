/* global test expect, describe, afterAll, beforeEach */

// environment.js expects to find config/webpacker.yml and resolved modules from
// the root of a Rails project

const { chdirTestApp, chdirCwd } = require('../../utils/helpers')

chdirTestApp()

const { resolve } = require('path')
const rules = require('../../rules')
const { ConfigList } = require('../../config_types')
const Environment = require('../base')

describe('Environment', () => {
  afterAll(chdirCwd)

  let environment

  describe('toWebpackConfig', () => {
    beforeEach(() => {
      environment = new Environment()
    })

    test('should return entry', () => {
      const config = environment.toWebpackConfig()
      expect(config.entry.application).toEqual(
        resolve('app', 'javascript', 'packs', 'application.js')
      )
    })

    test('should return multi file entry points', () => {
      const config = environment.toWebpackConfig()
      expect(config.entry.multi_entry.sort()).toEqual([
        resolve('app', 'javascript', 'packs', 'multi_entry.css'),
        resolve('app', 'javascript', 'packs', 'multi_entry.js')
      ])
    })

    test('should return output', () => {
      const config = environment.toWebpackConfig()
      expect(config.output.filename).toEqual('js/[name]-[contenthash].js')
      expect(config.output.chunkFilename).toEqual(
        'js/[name]-[contenthash].chunk.js'
      )
    })

    test('should return default loader rules for each file in config/loaders', () => {
      const config = environment.toWebpackConfig()
      const defaultRules = Object.keys(rules)
      const configRules = config.module.rules

      expect(defaultRules.length).toEqual(7)
      expect(configRules.length).toEqual(7)
    })

    test('should return cache path for nodeModules rule', () => {
      const nodeModulesLoader = rules.nodeModules.use.find(
        (rule) => rule.loader === 'babel-loader'
      )

      expect(nodeModulesLoader.options.cacheDirectory).toBeTruthy()
    })

    test('should return cache path for babel-loader rule', () => {
      const babelLoader = rules.babel.use.find(
        (rule) => rule.loader === 'babel-loader'
      )

      expect(babelLoader.options.cacheDirectory).toBeTruthy()
    })

    test('should return default plugins', () => {
      const config = environment.toWebpackConfig()
      expect(config.plugins.length).toEqual(4)
    })

    test('should return default resolveLoader', () => {
      const config = environment.toWebpackConfig()
      expect(config.resolveLoader.modules).toEqual(['node_modules'])
    })

    test('should return default resolve.modules with additions', () => {
      const config = environment.toWebpackConfig()
      expect(config.resolve.modules).toEqual([
        resolve('app', 'javascript'),
        resolve('app/assets'),
        resolve('/etc/yarn'),
        resolve('app/elm'),
        'node_modules'
      ])
    })

    test('returns plugins property as Array', () => {
      const config = environment.toWebpackConfig()

      expect(config.plugins).toBeInstanceOf(Array)
      expect(config.plugins).not.toBeInstanceOf(ConfigList)
    })
  })
})
