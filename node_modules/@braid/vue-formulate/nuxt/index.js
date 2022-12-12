import fs from 'fs'
import path from 'path'

export default function nuxtVueFormulate (moduleOptions) {
  let formulateOptions = Object.assign({}, this.options.formulate, moduleOptions)
  let configPath = false
  // check if we have a user-provided config path
  // or if a config file exists in the default location
  if (formulateOptions.configPath) {
    configPath = formulateOptions.configPath
  } else if (fs.existsSync(`${this.options.srcDir}/formulate.config.js`)) {
    configPath = '~/formulate.config.js'
  }
  // add the parsed config path back into the options object
  formulateOptions = Object.assign({}, formulateOptions, { configPath })
  // Register `plugin.js` template
  this.addPlugin({
    src: path.resolve(__dirname, 'plugin.js'),
    options: formulateOptions
  })
}
