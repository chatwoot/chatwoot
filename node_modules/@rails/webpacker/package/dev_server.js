const { isBoolean } = require('./utils/helpers')
const config = require('./config')

const fetch = (key) => {
  const value = process.env[key]
  return isBoolean(value) ? JSON.parse(value) : value
}

const devServerConfig = config.dev_server

if (devServerConfig) {
  const envPrefix = config.dev_server.env_prefix || 'WEBPACKER_DEV_SERVER'

  Object.keys(devServerConfig).forEach((key) => {
    const envValue = fetch(`${envPrefix}_${key.toUpperCase()}`)
    if (envValue !== undefined) devServerConfig[key] = envValue
  })
}

module.exports = devServerConfig || {}
