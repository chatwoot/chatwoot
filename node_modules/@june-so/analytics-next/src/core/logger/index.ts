export type LogLevel = 'debug' | 'info' | 'warn' | 'error'
export type LogMessage = {
  level: LogLevel
  message: string
  time?: Date
  extras?: object & {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    [key: string]: any
  }
}

export default class Logger {
  private _logs: LogMessage[] = []

  log = (level: LogLevel, message: string, extras?: object): void => {
    const time = new Date()
    this._logs.push({
      level,
      message,
      time,
      extras,
    })
  }

  public get logs(): LogMessage[] {
    return this._logs
  }

  public flush(): void {
    if (this.logs.length > 1) {
      const formatted = this._logs.reduce((logs, log) => {
        const line = {
          ...log,
          json: JSON.stringify(log.extras, null, ' '),
          extras: log.extras,
        }

        delete line['time']

        let key = log.time?.toISOString() ?? ''
        if (logs[key]) {
          key = `${key}-${Math.random()}`
        }

        return {
          ...logs,
          [key]: line,
        }
      }, {} as Record<string, LogMessage>)

      // ie doesn't like console.table
      if (console.table) {
        console.table(formatted)
      } else {
        console.log(formatted)
      }
    } else {
      this.logs.forEach((logEntry) => {
        const { level, message, extras } = logEntry

        if (level === 'info' || level === 'debug') {
          console.log(message, extras ?? '')
        } else {
          console[level](message, extras ?? '')
        }
      })
    }

    this._logs = []
  }
}
