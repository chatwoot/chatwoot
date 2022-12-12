import { segmentio, SegmentioSettings } from '..'
import { Analytics } from '../../../analytics'
// @ts-ignore isOffline mocked dependency is accused as unused
import { isOffline } from '../../../core/connection'
import { Plugin } from '../../../core/plugin'
import { pageEnrichment } from '../../page-enrichment'
import { scheduleFlush } from '../schedule-flush'
import { PersistedPriorityQueue } from '../../../lib/priority-queue/persisted'

jest.mock('../schedule-flush')

describe('Segment.io retries', () => {
  let options: SegmentioSettings
  let analytics: Analytics
  let segment: Plugin
  let queue: PersistedPriorityQueue

  beforeEach(async () => {
    jest.resetAllMocks()
    jest.restoreAllMocks()

    // @ts-expect-error reassign import
    isOffline = jest.fn().mockImplementation(() => true)

    options = { apiKey: 'foo' }
    analytics = new Analytics(
      { writeKey: options.apiKey },
      { retryQueue: true }
    )

    queue = new PersistedPriorityQueue(3, `test-Segment.io`)
    // @ts-expect-error reassign import
    PersistedPriorityQueue = jest.fn().mockImplementation(() => queue)

    segment = segmentio(analytics, options, {})

    await analytics.register(segment, pageEnrichment)
  })

  test('add events to the queue', async () => {
    jest.spyOn(queue, 'push')

    const ctx = await analytics.track('event')

    expect(scheduleFlush).toHaveBeenCalled()
    /* eslint-disable  @typescript-eslint/unbound-method */
    expect(queue.push).toHaveBeenCalled()
    expect(queue.length).toBe(1)
    expect(ctx.attempts).toBe(1)
    expect(isOffline).toHaveBeenCalledTimes(2)
  })
})
