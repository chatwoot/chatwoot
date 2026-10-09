let registeredEvents = {};

vi.mock('dashboard/composables/useKeyboardEvents', () => ({
  useKeyboardEvents: vi.fn(events => {
    registeredEvents = events;
  }),
}));

const mockRoute = {
  name: 'inbox_conversation',
  params: { accountId: '1', conversation_id: '10' },
};
const mockRouter = {
  push: vi.fn(),
};

vi.mock('vue-router', () => ({
  useRoute: () => mockRoute,
  useRouter: () => mockRouter,
}));

vi.mock('dashboard/composables/useConversationRoutePath', () => ({
  useConversationRoutePath: () => ({
    buildConversationListPath: () => 'accounts/1/dashboard',
  }),
}));

import { useChatListKeyboardEvents } from 'dashboard/composables/chatlist/useChatListKeyboardEvents';

describe('useChatListKeyboardEvents', () => {
  let listRef;

  beforeEach(() => {
    vi.clearAllMocks();
    registeredEvents = {};
    document.body.innerHTML = '';
    mockRoute.name = 'inbox_conversation';
    mockRoute.params = { accountId: '1', conversation_id: '10' };
    listRef = {
      value: document.createElement('div'),
    };
  });

  it('registers Alt+KeyJ, Alt+KeyK and Escape keyboard events', () => {
    useChatListKeyboardEvents(listRef);

    expect(registeredEvents['Alt+KeyJ']).toBeDefined();
    expect(registeredEvents['Alt+KeyK']).toBeDefined();
    expect(registeredEvents.Escape).toBeDefined();
    expect(registeredEvents.Escape.allowOnFocusedInput).toBe(false);
  });

  describe('Escape handler', () => {
    it('navigates to conversation list path when Escape is pressed on an active conversation route', () => {
      useChatListKeyboardEvents(listRef);

      registeredEvents.Escape.action();

      expect(mockRouter.push).toHaveBeenCalledWith('/app/accounts/1/dashboard');
    });

    it('does not navigate when a modal is open in DOM', () => {
      const modal = document.createElement('div');
      modal.className = 'woot-modal';
      document.body.appendChild(modal);

      useChatListKeyboardEvents(listRef);
      registeredEvents.Escape.action();

      expect(mockRouter.push).not.toHaveBeenCalled();
    });

    it('does not navigate when on a non-conversation route', () => {
      mockRoute.name = 'home';

      useChatListKeyboardEvents(listRef);
      registeredEvents.Escape.action();

      expect(mockRouter.push).not.toHaveBeenCalled();
    });
  });
});
