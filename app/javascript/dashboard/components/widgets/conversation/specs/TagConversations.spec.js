import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mount, flushPromises } from '@vue/test-utils';
import TagConversations from '../TagConversations.vue';
import SearchAPI from 'dashboard/api/search';
import { withFullI18n } from 'test-i18n';

withFullI18n();

vi.mock('dashboard/api/search', () => ({
  default: {
    conversations: vi.fn(),
  },
}));

vi.mock('dashboard/composables/useKeyboardNavigableList', () => ({
  useKeyboardNavigableList: vi.fn(),
}));

const CONVERSATIONS = [
  {
    id: 42,
    contact: { name: 'Alice Silva', thumbnail: 'alice.jpg' },
    inbox: { name: 'Email Support' },
  },
  {
    id: 99,
    contact: { name: 'Bob Santos', thumbnail: 'bob.jpg' },
    inbox: { name: 'WhatsApp' },
  },
];

const mountComponent = (props = {}) => {
  return mount(TagConversations, {
    props: {
      searchKey: '',
      ...props,
    },
    global: {
      stubs: { Avatar: true },
    },
  });
};

describe('TagConversations', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    SearchAPI.conversations.mockResolvedValue({
      data: { payload: { conversations: CONVERSATIONS } },
    });
  });

  it('renders no list when searchKey is empty', () => {
    const wrapper = mountComponent({ searchKey: '' });
    const list = wrapper.find('ul[role="listbox"]');
    expect(list.exists()).toBe(false);
  });

  it('fetches and renders conversations after debounced search', async () => {
    vi.useFakeTimers();
    const wrapper = mountComponent({ searchKey: '42' });
    vi.advanceTimersByTime(300);
    await flushPromises();

    expect(SearchAPI.conversations).toHaveBeenCalledWith({ q: '42' });
    const items = wrapper.findAll('[role="option"]');
    expect(items).toHaveLength(2);
    expect(items[0].text()).toContain('42');
    expect(items[0].text()).toContain('Alice Silva');
    vi.useRealTimers();
  });

  it('renders conversation items with display id, contact name and inbox', async () => {
    vi.useFakeTimers();
    const wrapper = mountComponent({ searchKey: 'test' });
    vi.advanceTimersByTime(300);
    await flushPromises();

    const items = wrapper.findAll('[role="option"]');
    expect(items[0].text()).toContain('42');
    expect(items[0].text()).toContain('Alice Silva');
    expect(items[0].text()).toContain('Email Support');
    expect(items[1].text()).toContain('99');
    expect(items[1].text()).toContain('Bob Santos');
    expect(items[1].text()).toContain('WhatsApp');
    vi.useRealTimers();
  });

  it('emits selectConversation with correct payload on click', async () => {
    vi.useFakeTimers();
    const wrapper = mountComponent({ searchKey: 'test' });
    vi.advanceTimersByTime(300);
    await flushPromises();

    const firstOption = wrapper.findAll('[role="option"]')[0];
    await firstOption.trigger('click');

    expect(wrapper.emitted('selectConversation')).toBeTruthy();
    expect(wrapper.emitted('selectConversation')[0][0]).toMatchObject({
      id: 42,
      type: 'conversation',
      displayName: '42',
    });
    vi.useRealTimers();
  });

  it('shows no results message when search returns empty', async () => {
    SearchAPI.conversations.mockResolvedValue({
      data: { payload: { conversations: [] } },
    });
    vi.useFakeTimers();
    const wrapper = mountComponent({ searchKey: 'nonexistent' });
    vi.advanceTimersByTime(300);
    await flushPromises();

    expect(wrapper.text()).toContain('No conversations found');
    vi.useRealTimers();
  });

  it('renders a section header', async () => {
    vi.useFakeTimers();
    const wrapper = mountComponent({ searchKey: 'test' });
    vi.advanceTimersByTime(300);
    await flushPromises();

    expect(wrapper.text()).toContain('Conversations');
    vi.useRealTimers();
  });
});
