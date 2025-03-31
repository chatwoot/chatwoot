import cookie from 'js-cookie'

const ajsCookieNames = [
  'ajs_user_id',
  'ajs_anonymous_id',
  'ajs_group_id',
] as const
const ajsLocalStorageKeys = ['ajs_user_traits', 'ajs_group_properties'] as const

export const getAjsBrowserStorage = () => {
  return getBrowserStorage({
    cookieNames: ajsCookieNames,
    localStorageKeys: ajsLocalStorageKeys,
  })
}

export const getAnonId = () => getAjsBrowserStorage().ajs_anonymous_id

export const clearAjsBrowserStorage = () => {
  return clearBrowserStorage({
    cookieNames: ajsCookieNames,
    localStorageKeys: ajsLocalStorageKeys,
  })
}

export function getBrowserStorage<
  CookieNames extends string,
  LSKeys extends string
>({
  cookieNames,
  localStorageKeys,
}: {
  cookieNames: readonly CookieNames[]
  localStorageKeys: readonly LSKeys[]
}): Record<CookieNames | LSKeys, string | {}> {
  const result = {} as ReturnType<typeof getBrowserStorage>

  const cookies = cookie.get()
  cookieNames.forEach((name) => {
    if (name in cookies) {
      result[name] = cookies[name]
    }
  })

  localStorageKeys.forEach((key) => {
    const value = localStorage.getItem(key)
    if (value !== null && typeof value !== 'undefined') {
      result[key] = JSON.parse(value)
    }
  })

  return result
}

export function clearBrowserStorage({
  cookieNames,
  localStorageKeys, // if no keys are passed, the entire thing is cleared
}: {
  cookieNames: string[] | readonly string[]
  localStorageKeys?: string[] | readonly string[]
}) {
  cookieNames.forEach((name) => {
    cookie.remove(name)
  })
  if (!localStorageKeys) {
    localStorage.clear()
  } else {
    localStorageKeys.forEach((key) => {
      localStorage.removeItem(key)
    })
  }
}
