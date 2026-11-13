import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import MessageMeta from './MessageMeta.vue';
import { provideMessageContext } from './provider.js';
import { messageTimestamp } from 'shared/helpers/timeHelper';

vi.mock('dashboard/composables/useInbox', () => ({
  useInbox: () => ({
    isAFacebookInbox: ref(false),
    isALineChannel: ref(false),
    isAPIInbox: ref(true),
    isASmsInbox: ref(false),
    isATelegramChannel: ref(false),
    isATwilioChannel: ref(false),
    isAWebWidgetInbox: ref(false),
    isAWhatsAppChannel: ref(false),
    isAnEmailChannel: ref(false),
    isAnInstagramChannel: ref(false),
    isATiktokChannel: ref(false),
  }),
}));

const mountMessageMeta = ({ createdAt, contentAttributes = {} }) => {
  const TestHost = defineComponent({
    components: { MessageMeta },
    setup() {
      provideMessageContext({
        status: ref('sent'),
        isPrivate: ref(false),
        createdAt: ref(createdAt),
        sourceId: ref(''),
        messageType: ref(1),
        contentAttributes: ref(contentAttributes),
      });
    },
    template: '<MessageMeta />',
  });

  const i18n = createI18n({
    legacy: false,
    locale: 'en',
    messages: { en: {} },
  });

  return mount(TestHost, {
    global: {
      plugins: [i18n],
      directives: { tooltip: {} },
      stubs: {
        Icon: { template: '<span />' },
        MessageStatus: { template: '<span />' },
      },
    },
  });
};

const renderedTime = wrapper => wrapper.find('time').text();

describe('MessageMeta', () => {
  it('shows createdAt when no externalCreatedAt is set', () => {
    const wrapper = mountMessageMeta({ createdAt: 1_726_344_000 });
    expect(renderedTime(wrapper)).toBe(
      messageTimestamp(1_726_344_000, 'LLL d, h:mm a')
    );
  });

  it('prefers externalCreatedAt given as unix seconds', () => {
    const wrapper = mountMessageMeta({
      createdAt: 1_726_344_000,
      contentAttributes: { externalCreatedAt: 1_598_889_600 },
    });
    expect(renderedTime(wrapper)).toBe(
      messageTimestamp(1_598_889_600, 'LLL d, h:mm a')
    );
  });

  it('accepts externalCreatedAt as a numeric string', () => {
    const wrapper = mountMessageMeta({
      createdAt: 1_726_344_000,
      contentAttributes: { externalCreatedAt: '1598889600' },
    });
    expect(renderedTime(wrapper)).toBe(
      messageTimestamp(1_598_889_600, 'LLL d, h:mm a')
    );
  });

  it('accepts externalCreatedAt as an ISO date string', () => {
    const wrapper = mountMessageMeta({
      createdAt: 1_726_344_000,
      contentAttributes: { externalCreatedAt: '2020-08-31T14:40:00Z' },
    });
    expect(renderedTime(wrapper)).toBe(
      messageTimestamp(1_598_884_800, 'LLL d, h:mm a')
    );
  });

  it('falls back to createdAt when externalCreatedAt cannot be parsed', () => {
    const wrapper = mountMessageMeta({
      createdAt: 1_726_344_000,
      contentAttributes: { externalCreatedAt: 'not-a-date' },
    });
    expect(renderedTime(wrapper)).toBe(
      messageTimestamp(1_726_344_000, 'LLL d, h:mm a')
    );
  });
});
