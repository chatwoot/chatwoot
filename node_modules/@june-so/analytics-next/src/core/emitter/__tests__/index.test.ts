import { Emitter } from '..'

describe(Emitter, () => {
  it('emits events', () => {
    const em = new Emitter()

    const fn = jest.fn()
    em.on('test', fn)
    em.emit('test', 'banana')

    expect(fn).toHaveBeenCalledWith('banana')
  })

  it('allows for subscribing to events', () => {
    const em = new Emitter()

    const fn = jest.fn()
    const anotherFn = jest.fn()

    em.on('test', fn)
    em.on('test', anotherFn)

    em.emit('test', 'banana', 'phone')

    expect(fn).toHaveBeenCalledWith('banana', 'phone')
    expect(anotherFn).toHaveBeenCalledWith('banana', 'phone')
  })

  it('allows for subscribing to the same event multiple times', () => {
    const em = new Emitter()

    const fn = jest.fn()

    em.on('test', fn)
    em.emit('test', 'banana')
    em.emit('test', 'phone')

    expect(fn).toHaveBeenCalledTimes(2)
    expect(fn).toHaveBeenCalledWith('banana')
    expect(fn).toHaveBeenCalledWith('phone')
  })

  it('allows for subscribers to subscribe only once', () => {
    const em = new Emitter()

    const fn = jest.fn()
    em.once('test', fn)

    // 2 emits
    em.emit('test', 'banana')
    em.emit('test', 'phone')

    expect(fn).toHaveBeenCalledTimes(1)
    expect(fn).toHaveBeenCalledWith('banana')
  })

  it('allows for unsubscribing', () => {
    const em = new Emitter()

    const fn = jest.fn()
    em.on('test', fn)

    // 2 emits
    em.emit('test', 'banana')
    em.emit('test', 'phone')

    em.off('test', fn)

    // 3rd emit
    em.emit('test', 'phone')

    expect(fn).toHaveBeenCalledTimes(2)
  })
})
