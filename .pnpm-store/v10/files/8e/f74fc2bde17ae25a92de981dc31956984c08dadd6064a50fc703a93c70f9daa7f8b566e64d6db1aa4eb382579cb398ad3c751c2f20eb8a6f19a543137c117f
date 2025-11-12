let { Plugins } = require('./load-plugins')
let calc = require('./calc')

/**
 * Run Size Limit and return the result
 *
 * @param  {functions[]} plugins   The list of plugins like `@size-limit/time`
 * @param  {string[]|object} files Path to files or internal config
 * @return {Promise<object>}     Project size
 */
module.exports = async function (plugins, files) {
  let pluginList = new Plugins(plugins.reduce((all, i) => all.concat(i), []))
  if (Array.isArray(files)) {
    files = {
      checks: [{ files }]
    }
  }

  await calc(pluginList, files, false)

  return files.checks.map(i => {
    let value = {}
    for (let prop of ['size', 'time', 'runTime', 'loadTime']) {
      if (typeof i[prop] !== 'undefined') value[prop] = i[prop]
    }
    return value
  })
}
