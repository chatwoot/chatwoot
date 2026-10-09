import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { usePolicy } from 'dashboard/composables/usePolicy';
import SearchAPI from 'dashboard/api/search';
import { useSearchCommands } from '../useSearchCommands';

vi.mock('vue-i18n');
vi.mock('vue-router');
vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables/usePolicy');
vi.mock('dashboard/api/search');

const conversation = {
  id: 12,
  inbox_id: 3,
  meta: { sender: { name: 'Sarah Lane', thumbnail: 'sarah.png' } },
  last_non_activity_message: { content: 'Invoice question' },
};

describe('useSearchCommands', () => {
  let getters;
  let permitted;

  beforeEach(() => {
    permitted = true;
    getters = {
      getCurrentAccountId: 1,
      getAllConversations: [conversation],
      'inboxes/getInbox': () => ({ name: 'Support' }),
    };
    useI18n.mockReturnValue({ t: key => key });
    useRouter.mockReturnValue({ push: vi.fn() });
    useMapGetter.mockImplementation(key => ({ value: getters[key] }));
    usePolicy.mockReturnValue({
      checkPermissions: () => permitted,
      isFeatureFlagEnabled: () => true,
    });
    SearchAPI.conversations.mockResolvedValue({
      data: {
        payload: {
          conversations: [
            {
              id: 12,
              contact: { name: 'Sarah Lane' },
              inbox: { name: 'Support' },
              message: { content: 'Invoice question' },
            },
            {
              id: 40,
              contact: { name: 'Sarah Connor' },
              inbox: { name: 'Sales' },
              message: { content: 'Hi' },
            },
          ],
        },
      },
    });
    SearchAPI.contacts.mockResolvedValue({
      data: {
        payload: { contacts: [{ id: 5, name: 'Sarah Lane', email: 's@x.io' }] },
      },
    });
    SearchAPI.articles.mockResolvedValue({
      data: {
        payload: {
          articles: [
            {
              id: 8,
              title: 'Refunds',
              portal_slug: 'help',
              locale: 'en',
              category_name: 'Billing',
            },
          ],
        },
      },
    });
  });

  it('answers from the loaded conversations without a request', () => {
    const { searchLoadedConversations } = useSearchCommands();
    const [item] = searchLoadedConversations({ text: 'sar' });

    expect(SearchAPI.conversations).not.toHaveBeenCalled();
    expect(item).toEqual(
      expect.objectContaining({
        id: 'conversation-12',
        title: 'Sarah Lane',
        subtitle: 'Invoice question',
        badge: 'Support',
        avatar: { name: 'Sarah Lane', src: 'sarah.png' },
      })
    );
  });

  it('opens the conversation when a result runs', () => {
    const { searchLoadedConversations } = useSearchCommands();
    searchLoadedConversations({ text: 'sar' })[0].run();

    expect(useRouter().push).toHaveBeenCalledWith(
      '/app/accounts/1/conversations/12'
    );
  });

  it('searches conversations remotely with the abort signal', async () => {
    const { searchConversations } = useSearchCommands();
    const signal = new AbortController().signal;
    const items = await searchConversations({ text: 'sarah', signal });

    expect(SearchAPI.conversations).toHaveBeenCalledWith({
      q: 'sarah',
      signal,
    });
    expect(items.map(item => item.id)).toEqual([
      'conversation-12',
      'conversation-40',
    ]);
  });

  it('maps contacts and articles to their pages', async () => {
    const { searchContacts, searchArticles } = useSearchCommands();
    const [contact] = await searchContacts({ text: 'sarah' });
    const [article] = await searchArticles({ text: 'refund' });

    contact.run();
    expect(useRouter().push).toHaveBeenCalledWith('/app/accounts/1/contacts/5');
    expect(contact.subtitle).toBe('s@x.io');

    article.run();
    expect(useRouter().push).toHaveBeenCalledWith(
      '/app/accounts/1/portals/help/en/articles/edit/8'
    );
    expect(article.subtitle).toBe('Billing');
  });

  it('returns nothing when the user may not search that record', async () => {
    permitted = false;
    const { searchLoadedConversations, searchContacts } = useSearchCommands();

    expect(searchLoadedConversations({ text: 'sar' })).toEqual([]);
    expect(await searchContacts({ text: 'sar' })).toEqual([]);
    expect(SearchAPI.contacts).not.toHaveBeenCalled();
  });

  it('offers the full search page for the query', () => {
    const { searchEverything } = useSearchCommands();
    const [item] = searchEverything({ text: 'sarah' });
    item.run();

    expect(useRouter().push).toHaveBeenCalledWith({
      name: 'search',
      query: { q: 'sarah' },
    });
  });
});
