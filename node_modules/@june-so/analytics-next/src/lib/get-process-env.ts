/**
 * Returns `process.env` if it is available in the environment.
 * Always returns an object make it similarly easy to use as `process.env`.
 */
export function getProcessEnv(): { [key: string]: string | undefined } {
  if (typeof process === 'undefined' || !process.env) {
    return {}
  }

  return process.env
}
