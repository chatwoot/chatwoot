import { Plugin } from '../../../core/plugin'
import { Analytics } from '../../../analytics'
import { Context } from '../../../core/context'
import { schemaFilter } from '..'
import { LegacySettings } from '../../../browser'
import { segmentio, SegmentioSettings } from '../../segmentio'

const settings: LegacySettings = {
  integrations: {
    'Braze Web Mode (Actions)': {},
    // note that Fullstory's name here doesn't contain 'Actions'
    Fullstory: {},
    'Segment.io': {},
  },
  remotePlugins: [
    {
      name: 'Braze Web Mode (Actions)',
      libraryName: 'brazeDestination',
      url:
        'https://cdn.segment.com/next-integrations/actions/braze/9850d2cc8308a89db62a.js',
      settings: {
        subscriptions: [
          {
            partnerAction: 'trackEvent',
          },
          {
            partnerAction: 'updateUserProfile',
          },
          {
            partnerAction: 'trackPurchase',
          },
        ],
      },
    },
    {
      // note that Fullstory name contains 'Actions'
      name: 'Fullstory (Actions)',
      libraryName: 'fullstoryDestination',
      url:
        'https://cdn.segment.com/next-integrations/actions/fullstory/35ea1d304f85f3306f48.js',
      settings: {
        subscriptions: [
          {
            partnerAction: 'trackEvent',
          },
          {
            partnerAction: 'identifyUser',
          },
        ],
      },
    },
  ],
}

const trackEvent: Plugin = {
  name: 'Braze Web Mode (Actions) trackEvent',
  type: 'destination',
  version: '1.0',

  load(_ctx: Context): Promise<void> {
    return Promise.resolve()
  },

  isLoaded(): boolean {
    return true
  },

  track: async (ctx) => ctx,
  identify: async (ctx) => ctx,
  page: async (ctx) => ctx,
  group: async (ctx) => ctx,
  alias: async (ctx) => ctx,
}

const trackPurchase: Plugin = {
  ...trackEvent,
  name: 'Braze Web Mode (Actions) trackPurchase',
}

const updateUserProfile: Plugin = {
  ...trackEvent,
  name: 'Braze Web Mode (Actions) updateUserProfile',
}

const amplitude: Plugin = {
  ...trackEvent,
  name: 'amplitude',
}

const fullstory: Plugin = {
  ...trackEvent,
  name: 'Fullstory (Actions) trackEvent',
}

describe('schema filter', () => {
  let options: SegmentioSettings
  let filterXt: Plugin
  let segment: Plugin
  let ajs: Analytics

  beforeEach(async () => {
    jest.resetAllMocks()
    jest.restoreAllMocks()

    options = { apiKey: 'foo' }
    ajs = new Analytics({ writeKey: options.apiKey })
    segment = segmentio(ajs, options, {})
    filterXt = schemaFilter({}, settings)

    jest.spyOn(segment, 'track')
    jest.spyOn(trackEvent, 'track')
    jest.spyOn(trackPurchase, 'track')
    jest.spyOn(updateUserProfile, 'track')
    jest.spyOn(amplitude, 'track')
    jest.spyOn(fullstory, 'track')
  })

  describe('plugins and destinations', () => {
    it('loads plugin', async () => {
      await ajs.register(filterXt)
      expect(filterXt.isLoaded()).toBe(true)
    })

    it('does not drop events when no plan is defined', async () => {
      await ajs.register(
        segment,
        trackEvent,
        trackPurchase,
        updateUserProfile,
        schemaFilter({}, settings)
      )

      await ajs.track('A Track Event')

      expect(segment.track).toHaveBeenCalled()
      expect(trackEvent.track).toHaveBeenCalled()
      expect(trackPurchase.track).toHaveBeenCalled()
      expect(updateUserProfile.track).toHaveBeenCalled()
    })

    it('drops an event when the event is disabled', async () => {
      await ajs.register(
        segment,
        trackEvent,
        trackPurchase,
        updateUserProfile,
        amplitude,
        schemaFilter(
          {
            hi: {
              enabled: true,
              integrations: {
                'Braze Web Mode (Actions)': false,
              },
            },
          },
          settings
        )
      )

      await ajs.track('hi')

      expect(segment.track).toHaveBeenCalled()
      expect(amplitude.track).toHaveBeenCalled()

      expect(trackEvent.track).not.toHaveBeenCalled()
      expect(trackPurchase.track).not.toHaveBeenCalled()
      expect(updateUserProfile.track).not.toHaveBeenCalled()
    })

    it('does not drop events with different names', async () => {
      await ajs.register(
        segment,
        trackEvent,
        trackPurchase,
        updateUserProfile,
        amplitude,
        schemaFilter(
          {
            'Fake Track Event': {
              enabled: true,
              integrations: { amplitude: false },
            },
          },
          settings
        )
      )

      await ajs.track('Track Event')

      expect(segment.track).toHaveBeenCalled()
      expect(amplitude.track).toHaveBeenCalled()
      expect(trackEvent.track).toHaveBeenCalled()
      expect(trackPurchase.track).toHaveBeenCalled()
      expect(updateUserProfile.track).toHaveBeenCalled()
    })

    it('drops enabled event for matching destination', async () => {
      await ajs.register(
        segment,
        trackEvent,
        trackPurchase,
        updateUserProfile,
        amplitude,
        schemaFilter(
          {
            'Track Event': {
              enabled: true,
              integrations: { amplitude: false },
            },
          },
          settings
        )
      )

      await ajs.track('Track Event')

      expect(segment.track).toHaveBeenCalled()
      expect(trackEvent.track).toHaveBeenCalled()
      expect(trackPurchase.track).toHaveBeenCalled()
      expect(updateUserProfile.track).toHaveBeenCalled()

      expect(amplitude.track).not.toHaveBeenCalled()
    })

    it('does not drop event for non-matching destination', async () => {
      const filterXt = schemaFilter(
        {
          'Track Event': {
            enabled: true,
            integrations: { 'not amplitude': false },
          },
        },
        settings
      )

      await ajs.register(
        segment,
        trackEvent,
        trackPurchase,
        updateUserProfile,
        amplitude,
        filterXt
      )

      await ajs.track('Track Event')

      expect(segment.track).toHaveBeenCalled()
      expect(trackEvent.track).toHaveBeenCalled()
      expect(trackPurchase.track).toHaveBeenCalled()
      expect(updateUserProfile.track).toHaveBeenCalled()
      expect(amplitude.track).toHaveBeenCalled()
    })

    it('does not drop enabled event with enabled destination', async () => {
      const filterXt = schemaFilter(
        {
          'Track Event': {
            enabled: true,
            integrations: { amplitude: true },
          },
        },
        settings
      )

      await ajs.register(
        segment,
        trackEvent,
        trackPurchase,
        updateUserProfile,
        amplitude,
        filterXt
      )

      await ajs.track('Track Event')

      expect(segment.track).toHaveBeenCalled()
      expect(trackEvent.track).toHaveBeenCalled()
      expect(trackPurchase.track).toHaveBeenCalled()
      expect(updateUserProfile.track).toHaveBeenCalled()
      expect(amplitude.track).toHaveBeenCalled()
    })

    it('properly sets event integrations object with enabled plan', async () => {
      const filterXt = schemaFilter(
        {
          'Track Event': {
            enabled: true,
            integrations: { amplitude: true },
          },
        },
        settings
      )

      await ajs.register(
        segment,
        trackEvent,
        trackPurchase,
        updateUserProfile,
        amplitude,
        filterXt
      )

      const ctx = await ajs.track('Track Event')

      expect(ctx.event.integrations).toEqual({ amplitude: true })
      expect(segment.track).toHaveBeenCalled()
    })

    it('sets event integrations object when integration is disabled', async () => {
      const filterXt = schemaFilter(
        {
          'Track Event': {
            enabled: true,
            integrations: { amplitude: false },
          },
        },
        settings
      )

      await ajs.register(
        segment,
        trackEvent,
        trackPurchase,
        updateUserProfile,
        amplitude,
        filterXt
      )

      const ctx = await ajs.track('Track Event')

      expect(segment.track).toHaveBeenCalled()
      expect(trackEvent.track).toHaveBeenCalled()
      expect(trackPurchase.track).toHaveBeenCalled()
      expect(updateUserProfile.track).toHaveBeenCalled()

      expect(amplitude.track).not.toHaveBeenCalled()
      expect(ctx.event.integrations).toEqual({ amplitude: false })
    })

    it('doesnt set event integrations object with different event', async () => {
      const filterXt = schemaFilter(
        {
          'Track Event': {
            enabled: true,
            integrations: { amplitude: true },
          },
        },
        settings
      )

      await ajs.register(
        segment,
        trackEvent,
        trackPurchase,
        updateUserProfile,
        amplitude,
        filterXt
      )

      const ctx = await ajs.track('Not Track Event')

      expect(ctx.event.integrations).toEqual({})
    })
  })

  describe('action destinations', () => {
    it('disables action destinations', async () => {
      const filterXt = schemaFilter(
        {
          'Track Event': {
            enabled: true,
            integrations: {
              'Braze Web Mode (Actions)': false,
            },
          },
          __default: {
            enabled: true,
            integrations: {},
          },
          hi: {
            enabled: true,
            integrations: {
              'Braze Web Mode (Actions)': false,
            },
          },
        },
        settings
      )

      await ajs.register(
        segment,
        trackEvent,
        trackPurchase,
        updateUserProfile,
        amplitude,
        filterXt
      )

      await ajs.track('Track Event')

      expect(segment.track).toHaveBeenCalled()
      expect(amplitude.track).toHaveBeenCalled()

      expect(trackEvent.track).not.toHaveBeenCalled()
      expect(trackPurchase.track).not.toHaveBeenCalled()
      expect(updateUserProfile.track).not.toHaveBeenCalled()

      await ajs.track('a non blocked event')

      expect(segment.track).toHaveBeenCalled()
      expect(amplitude.track).toHaveBeenCalled()

      expect(trackEvent.track).toHaveBeenCalled()
      expect(trackPurchase.track).toHaveBeenCalled()
      expect(updateUserProfile.track).toHaveBeenCalled()
    })

    it('covers different names between remote plugins and integrations', async () => {
      const filterXt = schemaFilter(
        {
          hi: {
            enabled: true,
            integrations: {
              // note that Fullstory's name here does not contain 'Actions'
              Fullstory: false,
            },
          },
        },
        settings
      )

      await ajs.register(
        segment,
        trackEvent,
        trackPurchase,
        updateUserProfile,
        amplitude,
        fullstory,
        filterXt
      )

      await ajs.track('hi')

      expect(segment.track).toHaveBeenCalled()
      expect(amplitude.track).toHaveBeenCalled()
      expect(trackEvent.track).toHaveBeenCalled()
      expect(trackPurchase.track).toHaveBeenCalled()
      expect(updateUserProfile.track).toHaveBeenCalled()

      expect(fullstory.track).not.toHaveBeenCalled()

      await ajs.track('a non blocked event')

      expect(segment.track).toHaveBeenCalled()
      expect(amplitude.track).toHaveBeenCalled()

      expect(trackEvent.track).toHaveBeenCalled()
      expect(trackPurchase.track).toHaveBeenCalled()
      expect(updateUserProfile.track).toHaveBeenCalled()
      expect(fullstory.track).toHaveBeenCalled()
    })
  })
})
