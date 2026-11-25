import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { defineComponent, h, nextTick, reactive, ref } from 'vue';
import { flushPromises, mount } from '@vue/test-utils';
import Whatsapp from '../Whatsapp.vue';
import WhatsappChannel from 'dashboard/api/channel/whatsappChannel';
import WhatsappLegacyProviderBanner from '../../components/WhatsappLegacyProviderBanner.vue';

// The picker fetches the session catalog on mount. Without this the real module reaches
// for axios and the composable's own catch swallows it, so every session provider would
// silently be missing from the picker rather than the test saying so.
vi.mock('dashboard/api/channel/whatsappChannel', () => ({
  default: { getSessionProviders: vi.fn() },
}));

const SESSION_CATALOG = [
  { key: 'uazapi', creatable: true, beta: true, fields: [] },
  { key: 'baileys', creatable: true, beta: false, legacy: true, fields: [] },
];

// Mutable reactive route — tests drive route.query / route.name through it
// to exercise how the parent reacts to navigation events.
let mockRoute;
const mockPush = vi.fn();
const mockReplace = vi.fn();
let originalChatwootConfig;

vi.mock('vue-router', async () => {
  const actual = await vi.importActual('vue-router');
  return {
    ...actual,
    useRoute: () => mockRoute,
    useRouter: () => ({ push: mockPush, replace: mockReplace }),
  };
});

// useAccount reads the Vuex store; these tests mount without one. Self-hosted
// behavior (not on cloud) keeps the embedded signup gate open, matching the
// scenarios below.
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({
    isCloudFeatureEnabled: () => false,
    isOnChatwootCloud: ref(false),
    // Meta's incident switch, off: the picker offers the embedded signup as usual.
    isMetaInboxCreationDisabled: ref(false),
  }),
}));

vi.mock('vue-i18n', async () => {
  const actual = await vi.importActual('vue-i18n');
  return {
    ...actual,
    useI18n: () => ({ t: key => key }),
    I18nT: defineComponent({
      name: 'I18nT',
      props: { keypath: { type: String, required: true }, tag: String },
      setup(props, { slots }) {
        return () =>
          h(
            props.tag || 'span',
            {},
            slots.default ? slots.default() : props.keypath
          );
      },
    }),
  };
});

// We don't care about feature_flags / branding here — render simple stubs.
const stubComponent = name =>
  defineComponent({
    name,
    template: `<div class="${name}-stub" />`,
  });

const ChannelSelectorStub = defineComponent({
  name: 'ChannelSelector',
  // Declared so the assertions can read them back with `props()`. eslint cannot see into
  // a string template, so it reads the props as unused.
  /* eslint-disable vue/no-unused-properties */
  props: {
    isBeta: { type: Boolean, default: false },
    isLegacy: { type: Boolean, default: false },
  },
  /* eslint-enable vue/no-unused-properties */
  template: '<div class="ChannelSelector-stub" />',
});

const WhatsappEmbeddedSignupStub = defineComponent({
  name: 'WhatsappEmbeddedSignup',
  // eslint-disable-next-line vue/no-unused-emit-declarations
  emits: ['leaving'],
  template: '<div class="WhatsappEmbeddedSignup-stub" />',
});

const EMBEDDED_SIGNUP_CONFIG = {
  whatsappAppId: 'appid',
  whatsappConfigurationId: 'configid',
};

const mountWhatsapp = (
  overrides = {},
  chatwootConfig = EMBEDDED_SIGNUP_CONFIG
) => {
  // window.chatwootConfig is read in setup() to decide whether to render the
  // embedded signup component. Force "configured" by default so a provider
  // selection of "whatsapp" routes to the embedded signup branch.
  window.chatwootConfig = chatwootConfig;

  return mount(Whatsapp, {
    props: {
      mode: 'convert',
      inbox: { id: 30, provider: 'baileys', name: 'Inbox 30' },
      ...overrides,
    },
    global: {
      stubs: {
        WhatsappEmbeddedSignup: WhatsappEmbeddedSignupStub,
        Twilio: stubComponent('Twilio'),
        ThreeSixtyDialogWhatsapp: stubComponent('ThreeSixtyDialogWhatsapp'),
        // Upstream's guided manual setup and its access-request dialog read the Vuex store;
        // these tests mount without one and never reach either branch.
        WhatsappManualSetup: stubComponent('WhatsappManualSetup'),
        CloudWhatsapp: stubComponent('CloudWhatsapp'),
        WhatsappAccessRequestDialog: stubComponent(
          'WhatsappAccessRequestDialog'
        ),
        ChannelSelector: ChannelSelectorStub,
        BaileysWhatsapp: stubComponent('BaileysWhatsapp'),
        ZapiWhatsapp: stubComponent('ZapiWhatsapp'),
        SessionWhatsapp: stubComponent('SessionWhatsapp'),
      },
    },
  });
};

const setRouteProvider = value => {
  if (value === undefined) {
    mockRoute.query = {};
  } else {
    mockRoute.query = { provider: value };
  }
};

describe('Whatsapp.vue (convert mode)', () => {
  beforeEach(() => {
    originalChatwootConfig = window.chatwootConfig;
    mockPush.mockReset();
    mockReplace.mockReset();
    WhatsappChannel.getSessionProviders.mockResolvedValue({
      data: { payload: SESSION_CATALOG },
    });
    mockRoute = reactive({
      name: 'settings_inbox_convert',
      params: { inboxId: 30 },
      query: {},
    });
  });

  afterEach(() => {
    window.chatwootConfig = originalChatwootConfig;
  });

  it('shows the provider picker when no provider is selected in the query', () => {
    const wrapper = mountWhatsapp();
    expect(wrapper.find('.ChannelSelector-stub').exists()).toBe(true);
    expect(wrapper.find('.WhatsappEmbeddedSignup-stub').exists()).toBe(false);
  });

  it('shows the embedded signup configuration when ?provider=whatsapp', async () => {
    setRouteProvider('whatsapp');
    const wrapper = mountWhatsapp();
    await nextTick();
    expect(wrapper.find('.WhatsappEmbeddedSignup-stub').exists()).toBe(true);
    expect(wrapper.find('.ChannelSelector-stub').exists()).toBe(false);
  });

  // Upstream's guided manual setup creates a new inbox. Converting an existing one has to reach
  // the fork's form, which dispatches `inboxes/convertProvider` for the inbox at hand; the
  // 4.18.0 merge had routed both modes to the guided setup.
  describe('manual setup without embedded signup configured', () => {
    it('renders the convert-aware form in convert mode', async () => {
      setRouteProvider('whatsapp');
      const wrapper = mountWhatsapp({}, {});
      await nextTick();
      expect(wrapper.find('.CloudWhatsapp-stub').exists()).toBe(true);
      expect(wrapper.find('.WhatsappManualSetup-stub').exists()).toBe(false);
    });

    it('renders the guided setup in create mode', async () => {
      setRouteProvider('whatsapp_manual');
      const wrapper = mountWhatsapp({ mode: 'create', inbox: null }, {});
      await nextTick();
      expect(wrapper.find('.WhatsappManualSetup-stub').exists()).toBe(true);
      expect(wrapper.find('.CloudWhatsapp-stub').exists()).toBe(false);
    });
  });

  // The badge is what tells the admin a provider is not settled yet, and it follows the
  // catalog rather than the label, so a provider leaving beta is a server-side change.
  it('badges the session providers the catalog reports as beta', async () => {
    const wrapper = mountWhatsapp();
    await flushPromises();

    const badged = wrapper
      .findAllComponents(ChannelSelectorStub)
      .filter(selector => selector.props('isBeta'));

    expect(
      wrapper.findAllComponents(ChannelSelectorStub).length
    ).toBeGreaterThan(badged.length);
    expect(badged).toHaveLength(1);
  });

  it('lists the providers in the agreed order', async () => {
    WhatsappChannel.getSessionProviders.mockResolvedValue({
      data: {
        payload: ['baileys', 'zapi', 'uazapi', 'native'].map(key => ({
          key,
          creatable: true,
          fields: [],
        })),
      },
    });
    const wrapper = mountWhatsapp({ mode: 'create', inbox: null });
    await flushPromises();

    const titles = wrapper
      .findAllComponents(ChannelSelectorStub)
      .map(selector => selector.attributes('title'));

    expect(titles).toEqual([
      'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD',
      'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.NATIVE',
      'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.TWILIO',
      'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.UAZAPI',
      'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.ZAPI',
      'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.BAILEYS',
    ]);
  });

  // Native without a running connector stays on the list, disabled and saying why, rather
  // than vanishing: the administrator who opens the picker is rarely the one who can start it.
  describe('native while no connector is running', () => {
    const unavailable = detail => ({
      data: {
        payload: [
          {
            key: 'native',
            creatable: false,
            beta: true,
            unavailable_reason: 'connector_not_running',
            unavailable_detail: detail,
            fields: [],
          },
          { key: 'baileys', creatable: true, legacy: true, fields: [] },
        ],
      },
    });
    const createMode = { mode: 'create', inbox: null };
    const nativeCard = wrapper =>
      wrapper
        .findAllComponents(ChannelSelectorStub)
        .find(
          selector =>
            selector.attributes('title') ===
            'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.NATIVE'
        );

    it('lists it disabled, with the reason and what the server last saw fail', async () => {
      WhatsappChannel.getSessionProviders.mockResolvedValue(
        unavailable('schema whatsapp_connector does not exist')
      );
      const wrapper = mountWhatsapp(createMode);
      await flushPromises();

      const card = nativeCard(wrapper);
      expect(card.attributes('disabled')).toBe('true');
      expect(card.attributes('description')).toBe(
        'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.NATIVE_CONNECTOR_NOT_RUNNING schema whatsapp_connector does not exist'
      );
      const cloud = wrapper
        .findAllComponents(ChannelSelectorStub)
        .find(
          selector =>
            selector.attributes('title') ===
            'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD'
        );
      expect(cloud.attributes('disabled')).toBe('false');
    });

    it('gives the reason alone when no failed start was published', async () => {
      WhatsappChannel.getSessionProviders.mockResolvedValue(unavailable(null));
      const wrapper = mountWhatsapp(createMode);
      await flushPromises();

      expect(nativeCard(wrapper).attributes('description')).toBe(
        'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.NATIVE_CONNECTOR_NOT_RUNNING'
      );
    });

    it('does not open its form from a hand-typed URL, nor recommend it from the legacy banner', async () => {
      WhatsappChannel.getSessionProviders.mockResolvedValue(unavailable(null));
      setRouteProvider('native');
      const wrapper = mountWhatsapp(createMode);
      await flushPromises();

      expect(wrapper.find('.SessionWhatsapp-stub').exists()).toBe(false);
      expect(wrapper.find('.ChannelSelector-stub').exists()).toBe(true);

      setRouteProvider('baileys');
      await flushPromises();
      expect(
        wrapper
          .findComponent(WhatsappLegacyProviderBanner)
          .props('nativeAvailable')
      ).toBe(false);
    });
  });

  describe('legacy providers', () => {
    const catalog = keys => ({
      data: {
        payload: [
          { key: 'native', creatable: keys.includes('native'), beta: true },
          { key: 'uazapi', creatable: true, beta: true },
          { key: 'zapi', creatable: true, legacy: true },
          { key: 'baileys', creatable: true, legacy: true },
        ].map(p => ({ fields: [], ...p })),
      },
    });
    const createMode = { mode: 'create', inbox: null };

    it('badges the providers the catalog reports as legacy, and only those', async () => {
      WhatsappChannel.getSessionProviders.mockResolvedValue(
        catalog(['native'])
      );
      const wrapper = mountWhatsapp(createMode);
      await flushPromises();

      const legacy = wrapper
        .findAllComponents(ChannelSelectorStub)
        .filter(selector => selector.props('isLegacy'))
        .map(selector => selector.attributes('title'));

      expect(legacy).toEqual([
        'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.ZAPI',
        'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.BAILEYS',
      ]);
    });

    it.each(['baileys', 'zapi'])(
      'warns on %s and recommends the native provider the account can pick',
      async provider => {
        WhatsappChannel.getSessionProviders.mockResolvedValue(
          catalog(['native'])
        );
        setRouteProvider(provider);
        const wrapper = mountWhatsapp(createMode);
        await flushPromises();

        const banner = wrapper.findComponent(WhatsappLegacyProviderBanner);
        expect(banner.exists()).toBe(true);
        expect(banner.props('nativeAvailable')).toBe(true);
        expect(banner.props('canConvert')).toBe(false);
      }
    );

    it('switches to the native provider from the banner', async () => {
      WhatsappChannel.getSessionProviders.mockResolvedValue(
        catalog(['native'])
      );
      setRouteProvider('baileys');
      const wrapper = mountWhatsapp(createMode);
      await flushPromises();

      await wrapper
        .findComponent(WhatsappLegacyProviderBanner)
        .find('button')
        .trigger('click');

      expect(mockPush).toHaveBeenCalledWith(
        expect.objectContaining({ query: { provider: 'native' } })
      );
    });

    it('does not recommend the native provider when the account cannot pick it', async () => {
      WhatsappChannel.getSessionProviders.mockResolvedValue(catalog([]));
      setRouteProvider('baileys');
      const wrapper = mountWhatsapp(createMode);
      await flushPromises();

      expect(
        wrapper
          .findComponent(WhatsappLegacyProviderBanner)
          .props('nativeAvailable')
      ).toBe(false);
    });

    it('does not recommend the native provider to a native inbox being converted', async () => {
      WhatsappChannel.getSessionProviders.mockResolvedValue(
        catalog(['native'])
      );
      setRouteProvider('baileys');
      const wrapper = mountWhatsapp({
        inbox: { id: 31, provider: 'native', name: 'Inbox 31' },
      });
      await flushPromises();

      const banner = wrapper.findComponent(WhatsappLegacyProviderBanner);
      expect(banner.props('nativeAvailable')).toBe(false);
      expect(banner.find('button').exists()).toBe(false);
    });

    it.each(['native', 'uazapi'])(
      'says nothing on %s, which is not legacy',
      async provider => {
        WhatsappChannel.getSessionProviders.mockResolvedValue(
          catalog(['native'])
        );
        setRouteProvider(provider);
        const wrapper = mountWhatsapp(createMode);
        await flushPromises();

        expect(
          wrapper.findComponent(WhatsappLegacyProviderBanner).exists()
        ).toBe(false);
      }
    );
  });

  // Reproduces the "flash" bug: a successful embedded signup runs
  // router.replace, the route's query.provider is cleared during the
  // navigation tail, and the still-mounted parent would re-render the
  // provider picker for a few frames between the success toast and the
  // unmount.
  describe('navigation tail after embedded signup success', () => {
    it('keeps the picker hidden once the child emits "leaving"', async () => {
      setRouteProvider('whatsapp');
      const wrapper = mountWhatsapp();
      await nextTick();
      expect(wrapper.find('.WhatsappEmbeddedSignup-stub').exists()).toBe(true);

      // Simulate the success path: child signals it is about to navigate,
      // then the route's query.provider is cleared (as router.replace would).
      await wrapper
        .findComponent(WhatsappEmbeddedSignupStub)
        .vm.$emit('leaving');
      setRouteProvider(undefined);
      await nextTick();

      // Neither the picker nor the configuration block should render.
      expect(wrapper.find('.ChannelSelector-stub').exists()).toBe(false);
      expect(wrapper.find('.WhatsappEmbeddedSignup-stub').exists()).toBe(false);
    });

    it('would flash the picker without the "leaving" signal (control)', async () => {
      setRouteProvider('whatsapp');
      const wrapper = mountWhatsapp();
      await nextTick();
      expect(wrapper.find('.WhatsappEmbeddedSignup-stub').exists()).toBe(true);

      // Simulate the route's query being cleared without the leaving signal.
      // This is the original buggy behavior: the picker reappears.
      setRouteProvider(undefined);
      await nextTick();

      expect(wrapper.find('.ChannelSelector-stub').exists()).toBe(true);
    });
  });
});
