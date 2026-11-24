import { nextTick } from 'vue';
import { config, shallowMount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import en from 'dashboard/i18n/locale/en/automation.json';
import hr from 'dashboard/i18n/locale/hr/automation.json';
import AutomationWaitCondition from './AutomationWaitCondition.vue';

const originalPlugins = config.global.plugins;

describe('automation wait duration localization', () => {
  afterEach(() => {
    config.global.plugins = originalPlugins;
  });

  it.each([
    ['hr', 1, '1 sat'],
    ['hr', 2, '2 sata'],
    ['hr', 5, '5 sati'],
    ['hr', 21, '21 sat'],
    ['en', 5, '5 hours'],
  ])('renders a %s wait of %s hours as %s', async (locale, count, expected) => {
    config.global.plugins = [
      createI18n({ legacy: false, locale, messages: { en, hr } }),
    ];
    const wrapper = shallowMount(AutomationWaitCondition, {
      props: {
        eventName: 'conversation_updated',
        conditions: [
          {
            attribute_key: 'status',
            values: ['pending'],
            query_operator: null,
          },
        ],
        delay: count * 60,
        unit: 'hours',
        isSavedWait: true,
        statusOptions: [],
        inboxOptions: [],
        filterTypes: [],
        removeFilter: vi.fn(),
      },
    });
    await nextTick();

    expect(wrapper.text()).toContain(expected);
    wrapper.unmount();
  });
});
