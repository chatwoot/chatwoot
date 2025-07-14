import {
  Alias,
  Facade,
  Group,
  Identify,
  Options,
  Page,
  Screen,
  Track,
} from '@segment/facade'
import { SegmentEvent } from '../core/events'

export type SegmentFacade = Facade<SegmentEvent> & {
  obj: SegmentEvent
}

export function toFacade(evt: SegmentEvent, options?: Options): SegmentFacade {
  let fcd = new Facade(evt, options)

  if (evt.type === 'track') {
    fcd = new Track(evt, options)
  }

  if (evt.type === 'identify') {
    fcd = new Identify(evt, options)
  }

  if (evt.type === 'page') {
    fcd = new Page(evt, options)
  }

  if (evt.type === 'alias') {
    fcd = new Alias(evt, options)
  }

  if (evt.type === 'group') {
    fcd = new Group(evt, options)
  }

  if (evt.type === 'screen') {
    fcd = new Screen(evt, options)
  }

  Object.defineProperty(fcd, 'obj', {
    value: evt,
    writable: true,
  })

  return fcd as SegmentFacade
}
