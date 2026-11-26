import { useAssistantSwitcher } from './useAssistantSwitcher';

const mocks = vi.hoisted(() => ({
  dispatch: vi.fn(),
  push: vi.fn(),
  route: { name: '', params: { accountId: 1, assistantId: 4 } },
}));

vi.mock('vue-router', () => ({
  useRoute: () => mocks.route,
  useRouter: () => ({ push: mocks.push }),
}));
vi.mock('dashboard/composables/store.js', () => ({
  useStore: () => ({ dispatch: mocks.dispatch }),
}));

describe('useAssistantSwitcher', () => {
  beforeEach(() => {
    mocks.dispatch.mockReset();
    mocks.push.mockReset();
  });

  it('loads the page data for the new assistant, then opens the same page for it', async () => {
    mocks.route.name = 'captain_assistants_documents_index';

    await useAssistantSwitcher().switchAssistant({ id: 9 });

    expect(mocks.dispatch).toHaveBeenCalledWith('captainDocuments/get', {
      assistantId: 9,
    });
    expect(mocks.push).toHaveBeenCalledWith({
      name: 'captain_assistants_documents_index',
      params: { accountId: 1, assistantId: 9 },
    });
  });

  it('opens the page without loading when the page fetches its own data', async () => {
    mocks.route.name = 'captain_assistants_responses_index';

    await useAssistantSwitcher().switchAssistant({ id: 9 });

    expect(mocks.dispatch).not.toHaveBeenCalled();
    expect(mocks.push).toHaveBeenCalledWith({
      name: 'captain_assistants_responses_index',
      params: { accountId: 1, assistantId: 9 },
    });
  });
});
