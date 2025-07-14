// @ts-nocheck
import unfetch from 'unfetch'
import { getGlobal } from './get-global'

/**
 * Wrapper around native `fetch` containing `unfetch` fallback.
 */
export const fetch: typeof global.fetch = (...args) => {
  const global = getGlobal()
  return ((global && global.fetch) || unfetch)(...args)
}
