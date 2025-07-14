import { isBrowser } from '../utils/environment'

export function isOnline(): boolean {
  if (isBrowser()) {
    return window.navigator.onLine
  }

  return true
}

export function isOffline(): boolean {
  return !isOnline()
}
