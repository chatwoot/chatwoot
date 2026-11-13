import { shallowMount } from '@vue/test-utils';
import InboxCard from '../InboxCard.vue';

const localeState = vi.hoisted(() => ({
  resolvedLocale: { value: 'zh-CN' },
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params) => params?.time || key,
  }),
}));

vi.mock('shared/composables/useLocale', () => ({
  useLocale: () => ({ resolvedLocale: localeState.resolvedLocale }),
}));

const UNREAD_DOT = 'p .bg-n-iris-10';
const SENDER_NAME = 'p .font-medium';

const mountCard = (inboxItem = {}) =>
  shallowMount(InboxCard, {
    props: {
      inboxItem: {
        id: 1,
        readAt: null,
        pushMessageBody: 'Jane Doe: Hello there',
        primaryActor: { meta: { sender: { name: 'Jane Doe' } } },
        ...inboxItem,
      },
      stateInbox: { name: 'Support', channelType: 'Channel::WebWidget' },
    },
  });

const messageText = wrapper => wrapper.get('p').text();

describe('InboxCard', () => {
  beforeEach(() => {
    localeState.resolvedLocale.value = 'zh-CN';
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-08-10T00:00:00Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('shows the sender name with emphasis followed by the message', () => {
    const wrapper = mountCard();

    expect(wrapper.get(SENDER_NAME).text()).toBe('Jane Doe:');
    expect(messageText(wrapper)).toBe('Jane Doe: Hello there');
  });

  it('shows the unread dot only for unread notifications', () => {
    expect(mountCard().find(UNREAD_DOT).exists()).toBe(true);
    expect(mountCard({ readAt: 1700000000 }).find(UNREAD_DOT).exists()).toBe(
      false
    );
  });

  it('drops the leading separator when there is no sender name', () => {
    const wrapper = mountCard({ pushMessageBody: ': Hello there' });

    expect(wrapper.find(SENDER_NAME).exists()).toBe(false);
    expect(messageText(wrapper)).toBe('Hello there');
  });

  it('shows the whole body as the message when there is no separator', () => {
    const wrapper = mountCard({ pushMessageBody: 'Hello there' });

    expect(wrapper.find(SENDER_NAME).exists()).toBe(false);
    expect(messageText(wrapper)).toBe('Hello there');
  });

  it('emphasises only the text before the first colon', () => {
    const wrapper = mountCard({ pushMessageBody: 'Jane Doe: Meet at 10:30' });

    expect(wrapper.get(SENDER_NAME).text()).toBe('Jane Doe:');
    expect(messageText(wrapper)).toBe('Jane Doe: Meet at 10:30');
  });

  it('shows markup in the sender name and message as text', () => {
    const name = 'Jane <img src="x">';
    const message = '<form><input name="field"></form><b>Hello</b>';
    const wrapper = mountCard({ pushMessageBody: `${name}: ${message}` });

    expect(wrapper.find('form').exists()).toBe(false);
    expect(wrapper.find('input').exists()).toBe(false);
    expect(wrapper.find('img').exists()).toBe(false);
    expect(wrapper.find('b').exists()).toBe(false);
    expect(wrapper.get(SENDER_NAME).text()).toBe(`${name}:`);
    expect(messageText(wrapper)).toBe(`${name}: ${message}`);
  });

  it('localizes the snoozed-until duration without directional words', () => {
    const wrapper = shallowMount(InboxCard, {
      props: {
        inboxItem: {
          snoozedUntil: '2026-08-10T02:00:00Z',
          primaryActor: {
            meta: { sender: { name: 'Agent' } },
          },
        },
        stateInbox: {},
      },
      global: {
        directives: {
          'dompurify-html': () => {},
        },
        stubs: {
          Avatar: true,
          CardPriorityIcon: true,
          Icon: true,
          InboxContextMenu: true,
          SLACardLabel: true,
        },
      },
    });

    expect(wrapper.text()).toContain('2小时');
    expect(wrapper.text()).not.toContain('后');
  });

  it('keeps the compact snoozed-until time for English locales', () => {
    localeState.resolvedLocale.value = 'en-US';

    const wrapper = shallowMount(InboxCard, {
      props: {
        inboxItem: {
          snoozedUntil: '2026-08-10T02:00:00Z',
          primaryActor: {
            meta: { sender: { name: 'Agent' } },
          },
        },
        stateInbox: {},
      },
      global: {
        directives: {
          'dompurify-html': () => {},
        },
        stubs: {
          Avatar: true,
          CardPriorityIcon: true,
          Icon: true,
          InboxContextMenu: true,
          SLACardLabel: true,
        },
      },
    });

    expect(wrapper.text()).toContain('about 2h');
  });
});
