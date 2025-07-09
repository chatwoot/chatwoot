module.exports = async function calc(plugins, config, createSpinner) {
  process.setMaxListeners(config.checks.reduce((a, i) => a + i.files.length, 1))

  async function step(number) {
    for (let plugin of plugins.list) {
      let spinner
      if (plugin['wait' + number] && createSpinner) {
        spinner = createSpinner(plugin['wait' + number]).start()
      }
      if (plugin['step' + number] || plugin['all' + number]) {
        try {
          if (plugin['all' + number]) {
            await plugin['all' + number](config)
          } else {
            await Promise.all(
              config.checks.map(i => {
                return plugin['step' + number](config, i)
              })
            )
          }
        } catch (e) {
          if (spinner) spinner.error()
          throw e
        }
      }
      if (spinner) spinner.success()
    }
  }

  async function callMethodForEachPlugin(methodName) {
    for (let plugin of plugins.list) {
      if (plugin[methodName]) {
        await Promise.all(
          config.checks.map(i => {
            return plugin[methodName](config, i)
          })
        )
      }
    }
  }

  try {
    await callMethodForEachPlugin('before')
    for (let i = 0; i <= 100; i++) await step(i)
  } finally {
    await callMethodForEachPlugin('finally')
  }
  for (let check of config.checks) {
    if (typeof check.sizeLimit !== 'undefined') {
      check.passed = check.sizeLimit >= check.size
    }
    if (typeof check.timeLimit !== 'undefined') {
      check.passed = check.timeLimit >= check.time
    }
    if (check.files && !check.files.length && check.path) {
      check.missed = true
      check.sizeLimit = undefined
      check.timeLimit = undefined
    }
  }
  config.failed = config.checks.some(i => i.passed === false)
  config.missed = config.checks.some(i => i.missed === true)
}
