/* global test expect, describe */

const { chdirTestApp, chdirCwd } = require('../utils/helpers')

chdirTestApp()

describe('DevServer', () => {
  beforeEach(() => jest.resetModules())
  afterAll(chdirCwd)

  test('with NODE_ENV and RAILS_ENV set to development', () => {
    process.env.NODE_ENV = 'development'
    process.env.RAILS_ENV = 'development'
    process.env.WEBPACKER_DEV_SERVER_HOST = '0.0.0.0'
    process.env.WEBPACKER_DEV_SERVER_PORT = 5000
    process.env.WEBPACKER_DEV_SERVER_DISABLE_HOST_CHECK = false

    const devServer = require('../dev_server')
    expect(devServer).toBeDefined()
    expect(devServer.host).toEqual('0.0.0.0')
    expect(devServer.port).toEqual('5000')
    expect(devServer.disable_host_check).toBe(false)
  })

  test('with custom env prefix', () => {
    const config = require('../config')
    config.dev_server.env_prefix = 'TEST_WEBPACKER_DEV_SERVER'

    process.env.NODE_ENV = 'development'
    process.env.RAILS_ENV = 'development'
    process.env.TEST_WEBPACKER_DEV_SERVER_HOST = '0.0.0.0'
    process.env.TEST_WEBPACKER_DEV_SERVER_PORT = 5000

    const devServer = require('../dev_server')
    expect(devServer).toBeDefined()
    expect(devServer.host).toEqual('0.0.0.0')
    expect(devServer.port).toEqual('5000')
  })

  test('with NODE_ENV and RAILS_ENV set to production', () => {
    process.env.RAILS_ENV = 'production'
    process.env.NODE_ENV = 'production'
    expect(require('../dev_server')).toEqual({})
  })
})
