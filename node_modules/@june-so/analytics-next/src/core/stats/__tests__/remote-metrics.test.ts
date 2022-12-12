import { mocked } from 'ts-jest/utils'
import unfetch from 'unfetch'
import { RemoteMetrics } from '../remote-metrics'

jest.mock('unfetch', () => {
  return jest.fn()
})

describe('remote metrics', () => {
  test('stores metrics in a queue when sampling', () => {
    const remote = new RemoteMetrics({
      sampleRate: 100,
    })
    remote.increment('analytics_js.banana', ['phone:1'])

    expect(remote.queue).toMatchInlineSnapshot(`
      Array [
        Object {
          "metric": "analytics_js.banana",
          "tags": Object {
            "library": "analytics.js",
            "library_version": "npm:next-1.36.5",
            "phone": "1",
          },
          "type": "Counter",
          "value": 1,
        },
      ]
    `)
  })

  test('does not store when not sampling', () => {
    const remote = new RemoteMetrics({
      sampleRate: 0,
    })
    remote.increment('analytics_js.banana', ['phone:1'])

    expect(remote.queue).toMatchInlineSnapshot(`Array []`)
  })

  test('ignores messages after reaching threshold', () => {
    const remote = new RemoteMetrics({
      sampleRate: 100,
      maxQueueSize: 3,
    })

    remote.increment('analytics_js.banana', ['phone:1'])
    remote.increment('analytics_js.banana', ['phone:1'])
    remote.increment('analytics_js.banana', ['phone:1'])
    remote.increment('analytics_js.banana', ['phone:1'])

    expect(remote.queue.length).toBe(3)
  })

  test('force flushes errors', () => {
    const remote = new RemoteMetrics({
      sampleRate: 100,
    })

    const spy = jest.spyOn(remote, 'flush')

    remote.increment('analytics_js.banana', ['phone:1'])
    expect(spy).not.toHaveBeenCalled()

    remote.increment('analytics_js.banana.error', ['phone:1'])
    expect(spy).toHaveBeenCalled()
  })

  test('sends requests on flush', async () => {
    const spy = mocked(unfetch).mockImplementation()

    const remote = new RemoteMetrics({
      sampleRate: 100,
    })

    remote.increment('analytics_js.banana', ['phone:1'])
    await remote.flush()

    expect(spy).toHaveBeenCalled()
    expect(spy.mock.calls[0]).toMatchInlineSnapshot(`
      Array [
        "https://api.june.so/sdk/m",
        Object {
          "body": "{\\"series\\":[{\\"type\\":\\"Counter\\",\\"metric\\":\\"analytics_js.banana\\",\\"value\\":1,\\"tags\\":{\\"phone\\":\\"1\\",\\"library\\":\\"analytics.js\\",\\"library_version\\":\\"npm:next-1.36.5\\"}}]}",
          "headers": Object {
            "Content-Type": "application/json",
          },
          "method": "POST",
        },
      ]
    `)
  })

  test('clears queue after sending', async () => {
    const remote = new RemoteMetrics({
      sampleRate: 100,
    })

    remote.increment('analytics_js.banana', ['phone:1'])
    expect(remote.queue.length).toBe(1)

    await remote.flush()
    expect(remote.queue.length).toBe(0)
  })

  test('does not crash on errors', async () => {
    const errorSpy = jest.spyOn(console, 'error').mockImplementation()

    const error = new Error('aaay')
    mocked(unfetch).mockImplementation(() => {
      throw error
    })

    const remote = new RemoteMetrics({
      sampleRate: 100,
    })

    remote.increment('analytics_js.banana', ['phone:1'])
    await remote.flush()

    expect(errorSpy).toHaveBeenCalledWith(error)
  })

  test('disables metrics reporting in case of errors', async () => {
    jest.spyOn(console, 'error').mockImplementation()

    const error = new Error('aaay')
    mocked(unfetch).mockImplementation(() => {
      throw error
    })

    const remote = new RemoteMetrics({
      sampleRate: 100,
    })

    remote.increment('analytics_js.banana', ['phone:1'])
    await remote.flush()

    expect(remote.sampleRate).toBe(0)
  })

  test('flushs on a schedule', () => {
    jest.useFakeTimers()

    const remote = new RemoteMetrics({
      sampleRate: 100,
      flushTimer: 100,
    })

    const flushSpy = jest.spyOn(remote, 'flush')

    remote.increment('analytics_js.banana', ['phone:1'])
    jest.advanceTimersByTime(500)

    expect(flushSpy).toHaveBeenCalledTimes(5)
  })
})
