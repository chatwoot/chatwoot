const crypto = require('crypto')
const babelJest = require('babel-jest')

module.exports = {
  process: require('./process'),
  getCacheKey: function getCacheKey(
    fileData,
    filename,
    configString,
    { config, instrument, rootDir }
  ) {
    return crypto
      .createHash('md5')
      .update(
        babelJest.getCacheKey(fileData, filename, configString, {
          config,
          instrument,
          rootDir
        }),
        'hex'
      )
      .digest('hex')
  }
}
