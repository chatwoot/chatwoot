import { validation } from '..'
import { Context } from '../../../core/context'
import { SegmentEvent } from '../../../core/events'

const validEvent: SegmentEvent = {
  type: 'track',
  anonymousId: 'abc',
  event: 'test',
  properties: {},
  traits: {},
}

describe('validation', () => {
  ;['track', 'identify', 'group', 'page', 'alias'].forEach((method) => {
    describe(method, () => {
      it('validates that the `event` exists', async () => {
        const val = async () =>
          // @ts-ignore
          validation[method](
            // @ts-ignore
            new Context()
          )

        await expect(val()).rejects.toMatchInlineSnapshot(
          `[Error: Event is missing]`
        )
      })

      it('validates that `event.event` exists', async () => {
        const val = async () =>
          // @ts-ignore
          validation[method](
            new Context({
              ...validEvent,
              event: undefined,
            })
          )

        if (method === 'track') {
          await expect(val()).rejects.toMatchInlineSnapshot(
            `[Error: Event is not a string]`
          )
        }
      })

      it('validates that `properties` or `traits` are objects', async () => {
        if (method === 'alias') {
          return
        }
        const val = async () =>
          // @ts-ignore
          validation[method](
            new Context({
              ...validEvent,
              properties: undefined,
              traits: undefined,
            })
          )

        await expect(val()).rejects.toMatchInlineSnapshot(
          `[Error: properties is not an object]`
        )
      })

      it('validates that it contains an user', async () => {
        const val = async () =>
          // @ts-ignore
          validation[method](
            new Context({
              ...validEvent,
              userId: undefined,
              anonymousId: undefined,
            })
          )

        await expect(val()).rejects.toMatchInlineSnapshot(
          `[Error: Missing userId or anonymousId]`
        )
      })
    })
  })
})
