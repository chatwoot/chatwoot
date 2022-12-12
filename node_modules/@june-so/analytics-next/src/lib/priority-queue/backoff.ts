type BackoffParams = {
  /** The number of milliseconds before starting the first retry. Default is 500 */
  minTimeout?: number

  /** The maximum number of milliseconds between two retries. Default is Infinity */
  maxTimeout?: number

  /** The exponential factor to use. Default is 2. */
  factor?: number

  /** The current attempt */
  attempt: number
}

export function backoff(params: BackoffParams): number {
  const random = Math.random() + 1
  const {
    minTimeout = 500,
    factor = 2,
    attempt,
    maxTimeout = Infinity,
  } = params
  return Math.min(random * minTimeout * Math.pow(factor, attempt), maxTimeout)
}
