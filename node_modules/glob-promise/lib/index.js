'use strict'

const glob = require('glob')

const promise = function (pattern, options) {
  return new Promise((resolve, reject) => {
    glob(pattern, options, (err, files) => err === null ? resolve(files) : reject(err))
  })
}

// default
module.exports = promise

// utility exports
module.exports.glob = glob
module.exports.Glob = glob.Glob
module.exports.hasMagic = glob.hasMagic
module.exports.promise = promise
module.exports.sync = glob.sync
