/* test expect, describe, afterAll, beforeEach */

const { resolve } = require('path')
const { chdirTestApp, chdirCwd } = require('../utils/helpers')

chdirTestApp()

describe('Custom environment', () => {
  afterAll(chdirCwd)

  describe('toWebpackConfig', () => {
    beforeEach(() => jest.resetModules())

    test('should use staging config and default production environment', () => {
      process.env.RAILS_ENV = 'staging'
      delete process.env.NODE_ENV

      const { environment } = require('../index')
      const config = environment.toWebpackConfig()

      expect(config.output.path).toEqual(resolve('public', 'packs-staging'))
      expect(config.output.publicPath).toEqual('/packs-staging/')
      expect(config).toMatchObject({
        devtool: 'source-map',
        stats: 'normal'
      })
    })
  })
})
