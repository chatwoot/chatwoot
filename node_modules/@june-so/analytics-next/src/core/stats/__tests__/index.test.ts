import Stats from '..'
import { RemoteMetrics } from '../remote-metrics'

describe(Stats, () => {
  test('starts out empty', () => {
    const stats = new Stats()
    expect(stats.metrics).toEqual([])
  })

  test('records increments', () => {
    const stats = new Stats()

    stats.increment('m1')
    stats.increment('m2', 2)
    stats.increment('m3', 3, ['test:env'])

    expect(stats.metrics).toEqual([
      {
        metric: 'm1',
        tags: [],
        timestamp: expect.any(Number),
        type: 'counter',
        value: 1,
      },
      {
        metric: 'm2',
        tags: [],
        timestamp: expect.any(Number),
        type: 'counter',
        value: 2,
      },
      {
        metric: 'm3',
        tags: ['test:env'],
        timestamp: expect.any(Number),
        type: 'counter',
        value: 3,
      },
    ])
  })

  test('records gauges', () => {
    const stats = new Stats()

    stats.gauge('m1', 1)
    stats.gauge('m2', 2, ['test:env'])

    expect(stats.metrics).toEqual([
      {
        metric: 'm1',
        tags: [],
        timestamp: expect.any(Number),
        type: 'gauge',
        value: 1,
      },
      {
        metric: 'm2',
        tags: ['test:env'],
        timestamp: expect.any(Number),
        type: 'gauge',
        value: 2,
      },
    ])
  })

  test('serializes metrics to a more compact format', () => {
    const stats = new Stats()

    stats.gauge('some_gauge', 31, ['test:env'])
    stats.increment('some_increment', 22, ['test:env'])

    expect(stats.serialize()).toEqual([
      {
        e: expect.any(Number),
        k: 'g',
        m: 'some_gauge',
        t: ['test:env'],
        v: 31,
      },
      {
        e: expect.any(Number),
        k: 'c',
        m: 'some_increment',
        t: ['test:env'],
        v: 22,
      },
    ])
  })

  test('flushes metrics', () => {
    jest.spyOn(console, 'table').mockImplementationOnce(() => {})

    const stats = new Stats()
    stats.gauge('some_gauge', 31, ['test:env'])
    stats.increment('some_increment', 22, ['test:env'])

    stats.flush()

    expect(stats.metrics).toEqual([])
    expect(console.table).toHaveBeenCalled()
  })

  test('forwards increments to remote metrics endpoint', () => {
    const remote = new RemoteMetrics()
    const spy = jest.spyOn(remote, 'increment')

    const stats = new Stats(remote)
    stats.increment('banana', 1, ['phone:1'])

    expect(spy).toHaveBeenCalledWith('banana', ['phone:1'])
  })
})
