import { Plugin } from '../../core/plugin'
import { Context } from '../../core/context'
import { SegmentEvent } from '../../core/events'
import fetch from 'node-fetch'
import { version } from '../../generated/version'

interface AnalyticsNodeSettings {
  writeKey: string
  apiHost: string
  httpScheme: string
  name: string
  type: Plugin['type']
  version: string
}

export async function post(
  event: SegmentEvent,
  writeKey: string,
): Promise<SegmentEvent> {
  const res = await fetch(`https://api.june.so/sdk/${event.type}`, {
    method: 'POST',
    body: JSON.stringify({...event, writeKey}),
    headers: { 'Content-Type': 'application/json' },
  })

  if (!res.ok) {
    throw new Error('Message Rejected')
  }

  return event
}

export function analyticsNode(settings: AnalyticsNodeSettings): Plugin {
  const send = async (ctx: Context): Promise<Context> => {
    ctx.updateEvent('context.library.name', 'analytics-node-next')
    ctx.updateEvent('context.library.version', version)
    ctx.updateEvent('_metadata.nodeVersion', process.versions.node)

    await post(ctx.event, settings.writeKey)
    return ctx
  }

  const plugin: Plugin = {
    name: settings.name,
    type: settings.type,
    version: settings.version,

    load: (ctx) => Promise.resolve(ctx),
    isLoaded: () => true,

    track: send,
    identify: send,
    page: send,
    alias: send,
    group: send,
    screen: send,
  }

  return plugin
}
