import { LegacySettings } from '../..'
import { mockIntegrationName } from './classic-destination'

export const cdnSettingsKitchenSink: LegacySettings = {
  integrations: {
    [mockIntegrationName]: {},
    'Customer.io': {
      siteId: 'abc123foofixture', // overwritten
      versionSettings: {
        version: '2.2.3',
        componentTypes: ['browser', 'server'],
      },
      type: 'browser',
      bundlingStatus: 'bundled',
    },
    FullStory: {
      debug: false,
      org: 'se',
      trackAllPages: false,
      trackCategorizedPages: false,
      trackNamedPages: false,
      versionSettings: {
        version: '3.0.1',
        componentTypes: ['browser'],
      },
      type: 'browser',
      bundlingStatus: 'bundled',
    },
    'Google Analytics': {
      anonymizeIp: false,
      classic: false,
      contentGroupings: {},
      dimensions: {},
      domain: '',
      doubleClick: false,
      enableServerIdentify: false,
      enhancedEcommerce: false,
      enhancedLinkAttribution: false,
      identifyCategory: '',
      identifyEventName: '',
      ignoredReferrers: [],
      includeSearch: false,
      metrics: {},
      mobileTrackingId: '',
      nameTracker: false,
      nonInteraction: false,
      optimize: '',
      protocolMappings: {},
      reportUncaughtExceptions: false,
      resetCustomDimensionsOnPage: [],
      sampleRate: 100,
      sendUserId: false,
      setAllMappedProps: true,
      siteSpeedSampleRate: 1,
      trackCategorizedPages: true,
      trackNamedPages: true,
      trackingId: 'UA-970334309-1',
      useGoogleAmpClientId: false,
      versionSettings: {
        version: '2.18.5',
        componentTypes: ['browser', 'ios', 'android', 'server'],
      },
      type: 'browser',
      bundlingStatus: 'unbundled',
    },
    'june.so': {
      apiKey: 'D8frB7upBChqDN9PMWksNvZYDaKJIYo6',
      unbundledIntegrations: ['Google Analytics'],
      addBundledMetadata: true,
      maybeBundledConfigIds: {
        'Customer.io': ['60104dde8882b933c2006d1f'],
        FullStory: ['6010547f5a1d4d46c418d68e'],
      },
      versionSettings: {
        version: '4.4.7',
        componentTypes: ['browser'],
      },
    },
  },
  plan: {
    track: {
      __default: {
        enabled: true,
        integrations: {},
      },
    },
    identify: {
      __default: {
        enabled: true,
      },
      address: {
        enabled: true,
      },
      avatar: {
        enabled: true,
      },
      bs: {
        enabled: true,
      },
      bsAdjective: {
        enabled: true,
      },
      bsBuzz: {
        enabled: true,
      },
      bsNoun: {
        enabled: true,
      },
      catchPhrase: {
        enabled: true,
      },
      catchPhraseAdjective: {
        enabled: true,
      },
      catchPhraseDescriptor: {
        enabled: true,
      },
      catchPhraseNoun: {
        enabled: true,
      },
      color: {
        enabled: true,
      },
      company: {
        enabled: true,
      },
      companyName: {
        enabled: true,
      },
      companySuffix: {
        enabled: true,
      },
      custom: {
        enabled: true,
      },
      department: {
        enabled: true,
      },
      domainName: {
        enabled: true,
      },
      domainSuffix: {
        enabled: true,
      },
      domainWord: {
        enabled: true,
      },
      email: {
        enabled: true,
      },
      exampleEmail: {
        enabled: true,
      },
      findName: {
        enabled: true,
      },
      firstName: {
        enabled: true,
      },
      gender: {
        enabled: true,
      },
      id: {
        enabled: true,
      },
      ip: {
        enabled: true,
      },
      ipv6: {
        enabled: true,
      },
      jobArea: {
        enabled: true,
      },
      jobDescriptor: {
        enabled: true,
      },
      jobTitle: {
        enabled: true,
      },
      jobType: {
        enabled: true,
      },
      lastName: {
        enabled: true,
      },
      mac: {
        enabled: true,
      },
      name: {
        enabled: true,
      },
      person: {
        enabled: true,
      },
      phone: {
        enabled: true,
      },
      prefix: {
        enabled: true,
      },
      price: {
        enabled: true,
      },
      product: {
        enabled: true,
      },
      productAdjective: {
        enabled: true,
      },
      productDescription: {
        enabled: true,
      },
      productMaterial: {
        enabled: true,
      },
      productName: {
        enabled: true,
      },
      protocol: {
        enabled: true,
      },
      suffix: {
        enabled: true,
      },
      suffixes: {
        enabled: true,
      },
      title: {
        enabled: true,
      },
      url: {
        enabled: true,
      },
      userAgent: {
        enabled: true,
      },
      userName: {
        enabled: true,
      },
      username: {
        enabled: true,
      },
      website: {
        enabled: true,
      },
    },
    group: {
      __default: {
        enabled: true,
      },
      coolKids: {
        enabled: true,
      },
    },
  },
  middlewareSettings: {
    routingRules: [
      {
        matchers: [
          {
            ir: '["and",["=","event",{"value":"munanyo"}],["and",["=","type",{"value":"track"}],["=","properties.referrer",{"value":"munyaaaanyo"}]]]',
            type: 'fql',
            config: {
              expr: 'event = "munanyo" and type = "track" and properties.referrer = "munyaaaanyo"',
            },
          },
        ],
        scope: 'destinations',
        target_type: 'workspace::project::destination::config',
        transformers: [
          [
            {
              type: 'drop_properties',
              config: {
                drop: {
                  properties: ['url'],
                },
              },
            },
          ],
        ],
        destinationName: 'Google Analytics',
      },
    ],
  },
  enabledMiddleware: {},
  metrics: {
    sampleRate: 0.1,
  },
  legacyVideoPluginsEnabled: true,
  remotePlugins: [],
}

export const cdnSettingsMinimal: LegacySettings = {
  integrations: {
    [mockIntegrationName]: {},
  },
}
