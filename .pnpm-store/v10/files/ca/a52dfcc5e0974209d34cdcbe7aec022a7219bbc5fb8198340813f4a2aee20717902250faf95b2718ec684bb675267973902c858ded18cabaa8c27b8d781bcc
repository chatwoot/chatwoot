import { EOL } from 'node:os'
import { Writable } from 'node:stream'

import { ListrLogger, ProcessOutput } from 'listr2'

const EOLRegex = new RegExp(EOL + '$')

const bindLogger = (consoleLogMethod) =>
  new Writable({
    write: function (chunk, encoding, next) {
      consoleLogMethod(chunk.toString().replace(EOLRegex, ''))
      next()
    },
  })

const getMainRendererOptions = ({ debug, quiet }, logger, env) => {
  if (quiet) {
    return {
      renderer: 'silent',
    }
  }

  if (env.NODE_ENV === 'test') {
    return {
      renderer: 'test',
      rendererOptions: {
        logger: new ListrLogger({
          processOutput: new ProcessOutput(bindLogger(logger.log), bindLogger(logger.error)),
        }),
      },
    }
  }

  // Better support for dumb terminals: https://en.wikipedia.org/wiki/Computer_terminal#Dumb_terminals
  if (debug || env.TERM === 'dumb') {
    return {
      renderer: 'verbose',
    }
  }

  return {
    renderer: 'update',
    rendererOptions: {
      formatOutput: 'truncate',
    },
  }
}

const getFallbackRenderer = ({ renderer }, { FORCE_COLOR }) => {
  if (renderer === 'silent' || renderer === 'test' || Number(FORCE_COLOR) > 0) {
    return renderer
  }

  return 'verbose'
}

export const getRenderer = (options, logger, env = process.env) => {
  const mainRendererOptions = getMainRendererOptions(options, logger, env)

  return {
    ...mainRendererOptions,
    fallbackRenderer: getFallbackRenderer(mainRendererOptions, env),
  }
}
