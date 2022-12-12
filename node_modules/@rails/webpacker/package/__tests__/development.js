/* test expect, describe, afterAll, beforeEach */

const { resolve } = require('path')
const { chdirTestApp, chdirCwd } = require('../utils/helpers')

chdirTestApp()

describe('Development environment', () => {
  afterAll(chdirCwd)

  describe('toWebpackConfig', () => {
    beforeEach(() => jest.resetModules())

    test('should use development config and environment including devServer if WEBPACK_DEV_SERVER', () => {
      process.env.RAILS_ENV = 'development'
      process.env.NODE_ENV = 'development'
      process.env.WEBPACK_DEV_SERVER = 'YES'
      const { environment } = require('../index')

      const config = environment.toWebpackConfig()
      expect(config.output.path).toEqual(resolve('public', 'packs'))
      expect(config.output.publicPath).toEqual('/packs/')
      expect(config).toMatchObject({
        devServer: {
          host: 'localhost',
          port: 3035
        }
      })
    })

    test('should use development config and environment if WEBPACK_DEV_SERVER', () => {
      process.env.RAILS_ENV = 'development'
      process.env.NODE_ENV = 'development'
      process.env.WEBPACK_DEV_SERVER = undefined
      const { environment } = require('../index')

      const config = environment.toWebpackConfig()
      expect(config.output.path).toEqual(resolve('public', 'packs'))
      expect(config.output.publicPath).toEqual('/packs/')
      expect(config.devServer).toEqual(undefined)
    })
  })
})
