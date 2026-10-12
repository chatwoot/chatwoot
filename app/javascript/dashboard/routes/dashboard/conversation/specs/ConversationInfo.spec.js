import { shallowMount } from '@vue/test-utils';
import ConversationInfo from '../ConversationInfo.vue';
import CustomAttributes from '../customAttributes/CustomAttributes.vue';

vi.mock('shared/composables/useExactTimestamp', () => ({
  useExactTimestamp: () => () => 'Nov 27, 2025, 9:05 PM',
}));

vi.mock(
  'dashboard/components/widgets/conversation/advancedFilterItems/languages',
  () => ({
    getLanguageName: code => (code === 'en' ? 'English' : ''),
  })
);

const mountComponent = (props = {}) =>
  shallowMount(ConversationInfo, {
    props,
    global: {
      mocks: {
        $t: key => key,
      },
    },
  });

describe('ConversationInfo', () => {
  it('passes the emptyStateMessage prop to CustomAttributes', () => {
    const wrapper = mountComponent();
    const customAttributes = wrapper.findComponent(CustomAttributes);

    expect(customAttributes.exists()).toBe(true);
    expect(customAttributes.props('emptyStateMessage')).toBe(
      'CONVERSATION_CUSTOM_ATTRIBUTES.NO_RECORDS_FOUND'
    );
  });

  it('filters out empty static elements when conversation attributes are empty', () => {
    const wrapper = mountComponent({
      conversationAttributes: {},
      contactAttributes: {},
    });
    const customAttributes = wrapper.findComponent(CustomAttributes);

    expect(customAttributes.props('staticElements')).toEqual([]);
  });

  it('computes static elements when conversation attributes are present', () => {
    const wrapper = mountComponent({
      conversationAttributes: {
        referer: 'https://chatwoot.com',
        browser_language: 'en',
        browser: {
          browser_name: 'Chrome',
          browser_version: '120.0',
          platform_name: 'macOS',
          platform_version: '14.0',
        },
      },
      contactAttributes: {
        created_at_ip: '192.168.1.1',
      },
    });
    const customAttributes = wrapper.findComponent(CustomAttributes);
    const staticElements = customAttributes.props('staticElements');

    expect(staticElements.length).toBeGreaterThan(0);
    const keys = staticElements.map(el => el.key);
    expect(keys).toContain('static-referer');
    expect(keys).toContain('static-browser-language');
    expect(keys).toContain('static-browser');
    expect(keys).toContain('static-platform');
    expect(keys).toContain('static-ip-address');
  });
});
