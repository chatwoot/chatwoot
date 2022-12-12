module.exports = function formatConfig(config) {
  if (typeof config === 'function') {
    return { '*': config }
  }

  return config
}
