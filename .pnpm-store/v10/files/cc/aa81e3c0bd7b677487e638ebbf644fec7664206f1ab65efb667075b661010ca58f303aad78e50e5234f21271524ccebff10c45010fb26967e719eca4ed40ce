module.exports = {
  error(process, args, config) {
    if (args && args.debug) {
      process.stderr.write(JSON.stringify(config, null, 2) + '\n')
    }
  },

  results(process, args, config) {
    if (args && args.debug) {
      process.stdout.write(JSON.stringify(config, null, 2) + '\n')
    }
  }
}
