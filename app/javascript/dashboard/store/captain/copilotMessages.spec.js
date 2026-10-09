import CopilotMessagesAPI from 'dashboard/api/captain/copilotMessages';
import copilotMessages from './copilotMessages';

vi.mock('dashboard/api/captain/copilotMessages', () => ({
  default: { get: vi.fn() },
}));

const setupStore = () => {
  const state = { records: [], meta: {}, uiFlags: {} };
  const commit = (type, payload) =>
    copilotMessages.mutations[type](state, payload);
  return { state, context: { state, commit } };
};

describe('Copilot message history', () => {
  beforeEach(() => {
    CopilotMessagesAPI.get.mockReset();
  });

  it('keeps both chats when history requests finish out of order', async () => {
    const requests = {};
    CopilotMessagesAPI.get.mockImplementation(
      threadId =>
        new Promise(resolve => {
          requests[threadId] = resolve;
        })
    );
    const { state, context } = setupStore();

    const first = copilotMessages.actions.get(context, {
      threadId: 1,
      accountId: 1,
    });
    const second = copilotMessages.actions.get(context, {
      threadId: 2,
      accountId: 1,
    });
    requests[2]({
      data: {
        payload: [{ id: 20, account_id: 1, copilot_thread: { id: 2 } }],
        meta: { total_count: 1, page: 1 },
      },
    });
    await second;
    requests[1]({
      data: {
        payload: [{ id: 10, account_id: 1, copilot_thread: { id: 1 } }],
        meta: { total_count: 1, page: 1 },
      },
    });
    await first;

    expect(copilotMessages.getters.getMessagesByThreadId(state)(2)).toEqual([
      { id: 20, account_id: 1, copilot_thread: { id: 2 } },
    ]);
    expect(state.records.map(message => message.id)).toEqual([20, 10]);
  });

  it('loads every message page before showing a long past chat', async () => {
    CopilotMessagesAPI.get
      .mockResolvedValueOnce({
        data: {
          payload: [{ id: 1, account_id: 1, copilot_thread: { id: 7 } }],
          meta: { total_count: 2, page: 1 },
        },
      })
      .mockResolvedValueOnce({
        data: {
          payload: [{ id: 2, account_id: 1, copilot_thread: { id: 7 } }],
          meta: { total_count: 2, page: 2 },
        },
      });
    const { state, context } = setupStore();

    await copilotMessages.actions.get(context, {
      threadId: 7,
      accountId: 1,
    });

    expect(CopilotMessagesAPI.get).toHaveBeenCalledWith(7, { page: 2 });
    expect(
      copilotMessages.getters
        .getMessagesByThreadId(state)(7)
        .map(message => message.id)
    ).toEqual([1, 2]);
  });
});
