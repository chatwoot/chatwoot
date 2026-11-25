import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mount, flushPromises } from '@vue/test-utils';
import ConversationPreviewCard from '../ConversationPreviewCard.vue';
import ConversationAPI from 'dashboard/api/conversations';
import { withFullI18n } from 'test-i18n';

withFullI18n();

vi.mock('dashboard/api/conversations', () => ({
  default: {
    show: vi.fn(),
  },
}));

const mockPush = vi.fn();
vi.mock('vue-router', () => ({
  useRouter: () => ({ push: mockPush }),
}));

vi.mock('dashboard/helper/URLHelper', () => ({
  frontendURL: path => `/app/${path}`,
  conversationUrl: ({ accountId, id }) =>
    `accounts/${accountId}/conversations/${id}`,
}));

vi.mock('date-fns', async () => {
  const actual = await vi.importActual('date-fns');
  return {
    ...actual,
    formatDistanceToNow: date => `${Math.floor(date.getTime() / 1000)} ago`,
  };
});

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: getter => {
    if (getter === 'inboxes/getInboxes') {
      return { value: [{ id: 5, name: 'Support Inbox' }] };
    }
    return {
      value: [
        { title: 'billing', color: '#ff6b6b' },
        { title: 'vip', color: '#ffd43b' },
      ],
    };
  },
}));

vi.mock('@chatwoot/utils', () => ({
  getContrastingTextColor: () => '#ffffff',
}));

const CONVERSATION = {
  id: 42,
  status: 'open',
  inbox_id: 5,
  last_activity_at: 1234567890,
  priority: 'high',
  labels: ['billing', 'vip'],
  meta: {
    sender: { name: 'Alice Silva', thumbnail: 'alice.jpg' },
    assignee: { name: 'Agent Bob' },
  },
  messages: [{ content: 'Hello, I need help with my order' }],
  last_non_activity_message: {
    content: 'Sure, let me check that for you.',
  },
};

const mountComponent = (props = {}) => {
  return mount(ConversationPreviewCard, {
    props: {
      displayId: '42',
      accountId: 1,
      ...props,
    },
    global: {
      stubs: { Avatar: true, Icon: true },
    },
  });
};

describe('ConversationPreviewCard', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    ConversationAPI.show.mockResolvedValue({ data: CONVERSATION });
  });

  it('renders nothing before conversation data is fetched', () => {
    ConversationAPI.show.mockResolvedValue({ data: null });
    const wrapper = mountComponent();
    expect(wrapper.find('a').exists()).toBe(false);
  });

  it('fetches and renders conversation data on mount', async () => {
    const wrapper = mountComponent();
    await flushPromises();

    expect(ConversationAPI.show).toHaveBeenCalledWith('42');
    expect(wrapper.find('a').exists()).toBe(true);
    expect(wrapper.text()).toContain('Alice Silva');
    expect(wrapper.text()).toContain('42');
  });

  it('shows status badge', async () => {
    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.text()).toContain('Open');
  });

  it('shows last message preview', async () => {
    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.text()).toContain('Sure, let me check that for you.');
  });

  it('shows assignee name', async () => {
    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.text()).toContain('Agent Bob');
  });

  it('shows labels with colors', async () => {
    const wrapper = mountComponent();
    await flushPromises();

    const labelEls = wrapper.findAll('[style]').filter(el => {
      return el.attributes('style')?.includes('background-color');
    });
    expect(labelEls.length).toBeGreaterThanOrEqual(2);
    expect(wrapper.text()).toContain('billing');
    expect(wrapper.text()).toContain('vip');
  });

  it('shows priority icon', async () => {
    const wrapper = mountComponent();
    await flushPromises();

    const iconStub = wrapper.findAll('icon-stub').find(el => {
      return el.attributes('icon') === 'i-lucide-arrow-up';
    });
    expect(iconStub).toBeTruthy();
  });

  it('generates correct conversation link', async () => {
    const wrapper = mountComponent();
    await flushPromises();

    const link = wrapper.find('a');
    expect(link.attributes('href')).toBe('/app/accounts/1/conversations/42');
  });

  it('navigates via router on click', async () => {
    const wrapper = mountComponent();
    await flushPromises();

    await wrapper.find('a').trigger('click');
    expect(mockPush).toHaveBeenCalledWith('/app/accounts/1/conversations/42');
  });
});
