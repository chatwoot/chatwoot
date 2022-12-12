const { resolve } = require('path')

module.exports = process.env.WEBPACKER_CONFIG || resolve('config', 'webpacker.yml')
