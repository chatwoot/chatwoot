import { createPinia, setActivePinia } from 'pinia';
import { useConversationsStore } from '../conversations';

vi.mock('widget-v2/api/conversations', () => ({
  fetchConversations: vi.fn(),
  fetchConversation: vi.fn(),
  createConversation: vi.fn(),
  resolveConversation: vi.fn(),
  updateLastSeen: vi.fn(() => Promise.resolve()),
  toggleTyping: vi.fn(),
}));

describe('useConversationsStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it('tracks conversations in their own section', () => {
    const store = useConversationsStore();
    store.upsert({ id: 1, widget_section: 'human', status: 'open' });
    store.upsertFromEvent({
      id: 2,
      status: 'pending',
      additional_attributes: { widget_section: 'ai' },
      meta: {},
    });
    store.sections.human.ids.push(1);

    expect(store.humanConversations.map(c => c.id)).toEqual([1]);
    expect(store.aiConversations.map(c => c.id)).toEqual([2]);
  });

  it('merges cable updates into existing conversations', () => {
    const store = useConversationsStore();
    store.upsert({ id: 1, status: 'pending', unread_count: 2 });
    store.upsertFromEvent({
      id: 1,
      status: 'open',
      additional_attributes: {},
      meta: { assignee: { name: 'Agent Smith', thumbnail: 'x.png' } },
    });

    const conversation = store.byId[1];
    expect(conversation.status).toEqual('open');
    expect(conversation.unread_count).toEqual(2);
    expect(conversation.assignee.name).toEqual('Agent Smith');
  });

  it('sums unread counts across conversations', () => {
    const store = useConversationsStore();
    store.upsert({ id: 1, unread_count: 2 });
    store.upsert({ id: 2, unread_count: 3 });

    expect(store.totalUnread).toEqual(5);
  });

  it('clears unread count when a conversation is marked seen', async () => {
    const store = useConversationsStore();
    store.upsert({ id: 1, unread_count: 4 });

    await store.markSeen(1);

    expect(store.byId[1].unread_count).toEqual(0);
  });
});
