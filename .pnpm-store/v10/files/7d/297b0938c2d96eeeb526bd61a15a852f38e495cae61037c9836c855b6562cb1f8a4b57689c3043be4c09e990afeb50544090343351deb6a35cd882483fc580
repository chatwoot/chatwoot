import { Context, ContextCancelation } from '../../core/context'
import { SegmentEvent } from '../../core/events'
import { Plugin } from '../../core/plugin'
import { SegmentFacade, toFacade } from '../../lib/to-facade'

export interface MiddlewareParams {
  payload: SegmentFacade

  integrations?: SegmentEvent['integrations']
  next: (payload: MiddlewareParams['payload'] | null) => void
}

export interface DestinationMiddlewareParams {
  payload: SegmentFacade
  integration: string
  next: (payload: MiddlewareParams['payload'] | null) => void
}

export type MiddlewareFunction = (
  middleware: MiddlewareParams
) => void | Promise<void>

export type DestinationMiddlewareFunction = (
  middleware: DestinationMiddlewareParams
) => void | Promise<void>

export async function applyDestinationMiddleware(
  destination: string,
  evt: SegmentEvent,
  middleware: DestinationMiddlewareFunction[]
): Promise<SegmentEvent | null> {
  // Clone the event so mutations are localized to a single destination.
  let modifiedEvent = toFacade(evt, {
    clone: true,
    traverse: false,
  }).rawEvent() as SegmentEvent
  async function applyMiddleware(
    event: SegmentEvent,
    fn: DestinationMiddlewareFunction
  ): Promise<SegmentEvent | null> {
    let nextCalled = false
    let returnedEvent: SegmentEvent | null = null

    await fn({
      payload: toFacade(event, {
        clone: true,
        traverse: false,
      }),
      integration: destination,
      next(evt) {
        nextCalled = true

        if (evt === null) {
          returnedEvent = null
        }

        if (evt) {
          returnedEvent = evt.obj
        }
      },
    })

    if (!nextCalled && returnedEvent !== null) {
      returnedEvent = returnedEvent as SegmentEvent
      returnedEvent.integrations = {
        ...event.integrations,
        [destination]: false,
      }
    }

    return returnedEvent
  }

  for (const md of middleware) {
    const result = await applyMiddleware(modifiedEvent, md)
    if (result === null) {
      return null
    }
    modifiedEvent = result
  }

  return modifiedEvent
}

export function sourceMiddlewarePlugin(
  fn: MiddlewareFunction,
  integrations: SegmentEvent['integrations']
): Plugin {
  async function apply(ctx: Context): Promise<Context> {
    let nextCalled = false

    await fn({
      payload: toFacade(ctx.event, {
        clone: true,
        traverse: false,
      }),
      integrations: integrations ?? {},
      next(evt) {
        nextCalled = true
        if (evt) {
          ctx.event = evt.obj
        }
      },
    })

    if (!nextCalled) {
      throw new ContextCancelation({
        retry: false,
        type: 'middleware_cancellation',
        reason: 'Middleware `next` function skipped',
      })
    }

    return ctx
  }

  return {
    name: `Source Middleware ${fn.name}`,
    type: 'before',
    version: '0.1.0',

    isLoaded: (): boolean => true,
    load: (ctx): Promise<Context> => Promise.resolve(ctx),

    track: apply,
    page: apply,
    identify: apply,
    alias: apply,
    group: apply,
  }
}
