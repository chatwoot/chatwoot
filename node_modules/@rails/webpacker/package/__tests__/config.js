/* global test expect, describe */

const { chdirCwd, chdirTestApp, resetEnv } = require('../utils/helpers')

chdirTestApp()

const config = require('../config')

describe('Config', () => {
  beforeEach(() => jest.resetModules() && resetEnv())
  afterAll(chdirCwd)

  test('public path', () => {
    process.env.RAILS_ENV = 'development'
    const config = require('../config')
    expect(config.publicPath).toEqual('/packs/')
  })

  test('public path with asset host', () => {
    process.env.RAILS_ENV = 'development'
    process.env.WEBPACKER_ASSET_HOST = 'http://foo.com/'
    const config = require('../config')
    expect(config.publicPath).toEqual('http://foo.com/packs/')
  })

  test('should return additional paths as listed in app config, with resolved paths', () => {
    expect(config.additional_paths).toEqual(
      [
        'app/assets',
        '/etc/yarn',
        'app/elm'
      ]
    )
  })

  test('should return extensions as listed in app config', () => {
    expect(config.extensions).toEqual([
      '.mjs',
      '.js',
      '.sass',
      '.scss',
      '.css',
      '.module.sass',
      '.module.scss',
      '.module.css',
      '.png',
      '.svg',
      '.gif',
      '.jpeg',
      '.jpg',
      '.elm'
    ])
  })

  test('should return static assets extensions as listed in app config', () => {
    expect(config.static_assets_extensions).toEqual([
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.tiff',
      '.ico',
      '.svg',
    ])
  })
})
