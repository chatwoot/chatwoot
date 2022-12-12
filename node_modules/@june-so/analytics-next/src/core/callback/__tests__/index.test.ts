import { invokeCallback } from '..'
import { Context } from '../../context'

describe(invokeCallback, () => {
  it('invokes a callback asynchronously', async () => {
    const ctx = new Context({
      type: 'track',
    })

    const fn = jest.fn()
    const returned = await invokeCallback(ctx, fn)

    expect(fn).toHaveBeenCalledWith(ctx)
    expect(returned).toBe(ctx)
  })

  it('ignores unexisting callbacks', async () => {
    const ctx = new Context({
      type: 'track',
    })

    const returned = await invokeCallback(ctx)
    expect(returned).toBe(ctx)
  })

  it('ignores the callback after a timeout', async () => {
    const ctx = new Context({
      type: 'track',
    })

    const slow = (_ctx: Context): Promise<void> => {
      return new Promise((resolve) => {
        setTimeout(resolve, 200)
      })
    }

    const returned = await invokeCallback(ctx, slow, 50)
    expect(returned).toBe(ctx)

    const logs = returned.logs()
    expect(logs[0].extras).toMatchInlineSnapshot(`
      Object {
        "error": [Error: Promise timed out],
      }
    `)

    expect(logs[0].level).toEqual('warn')
  })

  it('does not crash if the callback crashes', async () => {
    const ctx = new Context({
      type: 'track',
    })

    const boo = (_ctx: Context): Promise<void> => {
      throw new Error('👻 boo!')
    }

    const returned = await invokeCallback(ctx, boo)
    expect(returned).toBe(ctx)

    const logs = returned.logs()
    expect(logs[0].extras).toMatchInlineSnapshot(`
      Object {
        "error": [Error: 👻 boo!],
      }
    `)
    expect(logs[0].level).toEqual('warn')
  })
})
