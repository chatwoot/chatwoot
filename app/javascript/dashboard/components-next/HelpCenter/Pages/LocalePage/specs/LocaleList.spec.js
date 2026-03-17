import { shallowMount, flushPromises } from '@vue/test-utils';
import { defineComponent } from 'vue';
import LocaleList from '../LocaleList.vue';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

const mocks = vi.hoisted(() => ({
  store: {
    dispatch: vi.fn(),
  },
  useAlert: vi.fn(),
  useTrack: vi.fn(),
  updateUISettings: vi.fn(),
}));

vi.mock('dashboard/composables/store', () => ({
  useStore: () => mocks.store,
}));

vi.mock('dashboard/composables', () => ({
  useAlert: mocks.useAlert,
  useTrack: mocks.useTrack,
}));

vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({
    uiSettings: {
      value: {
        last_active_locale_code: 'es',
      },
    },
    updateUISettings: mocks.updateUISettings,
  }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

vi.mock('vue-router', () => ({
  useRoute: () => ({
    name: 'portals-locales-index',
  }),
}));

const LocaleCardStub = defineComponent({
  name: 'LocaleCard',
  template: '<div />',
});

const buildWrapper = props =>
  shallowMount(LocaleList, {
    props: {
      portal: {
        slug: 'draft-locales-demo',
        meta: {
          default_locale: 'en',
        },
      },
      locales: [
        { name: 'English', code: 'en', isDraft: false },
        { name: 'Spanish', code: 'es', isDraft: false },
      ],
      ...props,
    },
    global: {
      stubs: {
        LocaleCard: LocaleCardStub,
      },
    },
  });

describe('LocaleList', () => {
  beforeEach(() => {
    mocks.store.dispatch.mockReset();
    mocks.useAlert.mockReset();
    mocks.useTrack.mockReset();
    mocks.updateUISettings.mockReset();
  });

  it('does not track drafting when the locale update fails', async () => {
    mocks.store.dispatch.mockRejectedValue(
      new Error('Unable to update locale')
    );

    const wrapper = buildWrapper();

    wrapper.findAllComponents(LocaleCardStub)[1].vm.$emit('action', {
      action: 'move-to-draft',
    });
    await flushPromises();

    expect(mocks.useTrack).not.toHaveBeenCalled();
    expect(mocks.useAlert).toHaveBeenCalledWith('Unable to update locale');
  });

  it('tracks publishing only after a successful locale update', async () => {
    mocks.store.dispatch.mockResolvedValue({});

    const wrapper = buildWrapper({
      locales: [
        { name: 'English', code: 'en', isDraft: false },
        { name: 'Spanish', code: 'es', isDraft: true },
      ],
    });

    wrapper.findAllComponents(LocaleCardStub)[1].vm.$emit('action', {
      action: 'publish-locale',
    });
    await flushPromises();

    expect(mocks.useTrack).toHaveBeenCalledWith(PORTALS_EVENTS.PUBLISH_LOCALE, {
      locale: 'es',
      from: 'portals-locales-index',
    });
  });
});
