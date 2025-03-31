import { QueryStringParams } from '.'

/**
 * Returns an object containing only the properties prefixed by the input
 * string.
 * Ex: prefix('ajs_traits_', { ajs_traits_address: '123 St' })
 * will return { address: '123 St' }
 **/
export function pickPrefix(
  prefix: string,
  object: QueryStringParams
): QueryStringParams {
  return Object.keys(object).reduce((acc: QueryStringParams, key: string) => {
    if (key.startsWith(prefix)) {
      const field = key.substr(prefix.length)
      acc[field] = object[key]!
    }
    return acc
  }, {})
}
