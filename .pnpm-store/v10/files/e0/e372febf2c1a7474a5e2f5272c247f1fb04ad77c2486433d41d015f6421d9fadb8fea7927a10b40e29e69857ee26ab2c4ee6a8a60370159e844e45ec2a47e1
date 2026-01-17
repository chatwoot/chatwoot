import {
  JSDOM,
  VirtualConsole,
} from 'jsdom'
import { populateGlobal } from './util.js'

export function createDomEnv () {
  const dom = new JSDOM(
    '<!DOCTYPE html>',
    {
      pretendToBeVisual: true,
      runScripts: 'dangerously',
      url: 'http://localhost:3000',
      virtualConsole: console && global.console ? new VirtualConsole().sendTo(global.console) : undefined,
      includeNodeLocations: false,
      contentType: 'text/html',
    },
  )

  const { keys, originals } = populateGlobal(global, dom.window, { bindFunctions: true })

  function destroy () {
    keys.forEach(key => delete global[key])
    originals.forEach((v, k) => {
      global[k] = v
    })
  }

  window.ResizeObserver = window.ResizeObserver || class ResizeObserver {
    disconnect (): void { /* noop */ }
    observe (target: Element, options?: ResizeObserverOptions): void { /* noop */ }
    unobserve (target: Element): void { /* noop */ }
  }

  return {
    window,
    destroy,
  }
}
