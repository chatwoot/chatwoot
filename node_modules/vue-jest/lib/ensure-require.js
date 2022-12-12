const throwError = require('./utils').throwError

module.exports = function(name, deps) {
  let i, len
  let missing = []
  if (typeof deps === 'string') {
    deps = [deps]
  }
  for (i = 0, len = deps.length; i < len; i++) {
    let mis
    let req = deps[i]
    if (typeof req === 'string') {
      mis = req
    } else {
      mis = req[1]
      req = req[0]
    }
    try {
      // hack for babel-runtime because it does not expose "main" field
      if (req === 'babel-runtime') {
        req = 'babel-runtime/core-js'
      }
      require.resolve(req)
    } catch (e) {
      missing.push(mis)
    }
  }
  if (missing.length > 0) {
    let message = 'You are trying to use "' + name + '". '
    let npmInstall = 'npm install --save-dev ' + missing.join(' ')
    if (missing.length > 1) {
      const last = missing.pop()
      message += missing.join(', ') + ' and ' + last + ' are '
    } else {
      message += missing[0] + ' is '
    }
    message += 'missing.\n\nTo install run:\n' + npmInstall
    throwError(message)
  }
}
