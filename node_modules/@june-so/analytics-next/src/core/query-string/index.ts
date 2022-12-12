import { pickPrefix } from './pickPrefix'
import { Analytics } from '../../analytics'
import { Context } from '../context'

export interface QueryStringParams {
  [key: string]: string | null
}

export function queryString(
  analytics: Analytics,
  query: string
): Promise<Context[]> {
  const a = document.createElement('a')
  a.href = query
  const parsed = a.search.slice(1)

  const params = parsed.split('&').reduce((acc: QueryStringParams, str) => {
    const [k, v] = str.split('=')
    acc[k] = decodeURI(v).replace('+', ' ')
    return acc
  }, {})

  const calls = []

  /* eslint-disable @typescript-eslint/camelcase */
  const { ajs_uid, ajs_event, ajs_aid } = params

  if (ajs_uid) {
    const uid = Array.isArray(params.ajs_uid)
      ? params.ajs_uid[0]
      : params.ajs_uid
    const traits = pickPrefix('ajs_trait_', params)

    calls.push(analytics.identify(uid, traits))
  }

  if (ajs_event) {
    const event = Array.isArray(params.ajs_event)
      ? params.ajs_event[0]
      : params.ajs_event
    const props = pickPrefix('ajs_prop_', params)
    calls.push(analytics.track(event, props))
  }

  if (ajs_aid) {
    const anonId = Array.isArray(params.ajs_aid)
      ? params.ajs_aid[0]
      : params.ajs_aid
    analytics.setAnonymousId(anonId)
  }
  /* eslint-enable @typescript-eslint/camelcase */

  return Promise.all(calls)
}
