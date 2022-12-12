import Logger from '..'

describe(Logger, () => {
  let logger: Logger

  beforeEach(() => {
    logger = new Logger()
  })

  it('logs events at different levels', () => {
    logger.log('debug', 'Debugging', { test: 'debug', emoji: '🐛' })
    logger.log('info', 'Info', { test: 'info', emoji: '📰' })
    logger.log('warn', 'Warning', { test: 'warn', emoji: '⚠️' })
    logger.log('error', 'Error', { test: 'error', emoji: '💥' })

    expect(logger.logs).toEqual([
      {
        extras: {
          emoji: '🐛',
          test: 'debug',
        },
        level: 'debug',
        message: 'Debugging',
        time: expect.any(Date),
      },
      {
        extras: {
          emoji: '📰',
          test: 'info',
        },
        level: 'info',
        message: 'Info',
        time: expect.any(Date),
      },
      {
        extras: {
          emoji: '⚠️',
          test: 'warn',
        },
        level: 'warn',
        message: 'Warning',
        time: expect.any(Date),
      },
      {
        extras: {
          emoji: '💥',
          test: 'error',
        },
        level: 'error',
        message: 'Error',
        time: expect.any(Date),
      },
    ])
  })

  it('flushes logs to the console', () => {
    jest.spyOn(console, 'table').mockImplementationOnce(() => {})

    logger.log('info', 'my log')
    logger.log('debug', 'my log')

    logger.flush()
    expect(console.table).toHaveBeenCalled()
    expect(logger.logs).toEqual([])
  })
})
