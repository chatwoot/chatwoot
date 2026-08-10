import { shallowMount } from '@vue/test-utils';
import InboxCard from '../InboxCard.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params) => params?.time || key,
  }),
}));

vi.mock('shared/composables/useLocale', () => ({
  useLocale: () => ({ resolvedLocale: { value: 'zh-CN' } }),
}));

describe('InboxCard', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-08-10T00:00:00Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('localizes the snoozed-until relative time before abbreviating it', () => {
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

    expect(wrapper.text()).toContain('2小时后');
  });
});
