import { LegacySettings } from '../..'
import { createSuccess } from '../factories'
import { cdnSettingsMinimal } from './cdn-settings'

export const createMockFetchImplementation = (
  cdnSettings: Partial<LegacySettings> = {}
) => {
  return (url: RequestInfo, req?: RequestInit) => {
    const reqUrl = url.toString()
    if (!req || (req.method === 'get' && reqUrl.includes('cdn.june.so'))) {
      // GET https://cdn.june.so/v1/projects/{writeKey}
      return createSuccess({ ...cdnSettingsMinimal, ...cdnSettings })
    }

    if (req?.method === 'post' && reqUrl.includes('api.june.so')) {
      // POST https://api.june.so/sdk/{event.type}
      return createSuccess({ success: true }, { status: 201 })
    }

    throw new Error(
      `no match found for request (url:${url}, req:${JSON.stringify(req)})`
    )
  }
}
