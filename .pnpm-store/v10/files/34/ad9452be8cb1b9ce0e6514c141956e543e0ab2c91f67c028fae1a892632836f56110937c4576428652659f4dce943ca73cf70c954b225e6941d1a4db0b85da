import { EVENT_SEND } from './const'

export async function logEvent(name: string, argument) {
  console.log('[histoire] Event fired', { name, argument })
  const event = {
    name,
    argument: JSON.parse(stringifyEvent(argument)), // Needed for HTMLEvent that can't be cloned
  }
  if (location.href.includes('__sandbox')) {
    window.parent?.postMessage({
      type: EVENT_SEND,
      event,
    })
  }
  else {
    const { useEventsStore } = await import('../stores/events.js')
    useEventsStore().addEvent(event)
  }
}

function stringifyEvent(e) {
  const obj = {}
  for (const k in e) {
    obj[k] = e[k]
  }
  return JSON.stringify(obj, (k, v) => {
    if (v instanceof Node) return 'Node'
    if (v instanceof Window) return 'Window'
    return v
  }, ' ')
}
