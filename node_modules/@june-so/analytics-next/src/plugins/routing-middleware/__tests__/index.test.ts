/* eslint-disable @typescript-eslint/camelcase */
import { tsubMiddleware } from '..'
import { toFacade } from '../../../lib/to-facade'

describe('tsub middleware', () => {
  const rules = [
    {
      matchers: [
        {
          ir: '["=","event",{"value":"Item Impression"}]',
          type: 'fql',
        },
      ],
      scope: 'destinations',
      target_type: 'workspace::project::destination',
      transformers: [[{ type: 'drop' }]],
      destinationName: 'Google Tag Manager',
    },
  ]

  const middleware = tsubMiddleware(rules)

  it('can apply tsub operations', () => {
    let payload
    const next = jest.fn().mockImplementation((transformed) => {
      payload = transformed?.obj
    })

    middleware({
      integration: 'Google Tag Manager',
      next,
      payload: toFacade({
        type: 'track',
        event: 'Item Impression',
      }),
    })

    expect(next).toHaveBeenCalled()
    expect(payload).toMatchInlineSnapshot(`null`)
  })

  it("won't match different destinations", () => {
    let payload
    const next = jest.fn().mockImplementation((transformed) => {
      payload = transformed?.obj
    })

    middleware({
      integration: 'Google Analytics',
      next,
      payload: toFacade({
        type: 'track',
        event: 'Item Impression',
      }),
    })

    expect(next).toHaveBeenCalled()
    expect(payload).toMatchInlineSnapshot(`
      Object {
        "event": "Item Impression",
        "type": "track",
      }
    `)
  })
})
