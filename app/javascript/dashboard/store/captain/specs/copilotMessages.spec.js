import { createStore } from 'vuex';
import copilotMessages from '../copilotMessages';
import API from 'dashboard/api/captain/copilotMessages';

vi.mock('dashboard/api/captain/copilotMessages', () => ({
  default: { get: vi.fn() },
}));

describe('Copilot message history', () => {
  it('merges older pages without losing other sessions or overwriting websocket updates', async () => {
    const store = createStore({
      modules: {
        copilotMessages: { ...copilotMessages, state: { records: [] } },
      },
    });
    const message = (id, threadId, content) => ({
      id,
      copilot_thread: { id: threadId },
      message: { content },
    });
    let finish;
    API.get.mockImplementation(
      () =>
        new Promise(resolve => {
          finish = resolve;
        })
    );
    const request = store.dispatch('copilotMessages/getPage', {
      threadId: 1,
      page: 2,
    });
    await store.dispatch(
      'copilotMessages/upsert',
      message(20, 1, 'Stream complete')
    );
    await store.dispatch(
      'copilotMessages/upsert',
      message(30, 2, 'Other chat')
    );
    finish({
      data: {
        payload: [message(10, 1, 'Older'), message(20, 1, 'Stale snapshot')],
        meta: { next_page: null },
      },
    });
    await request;
    expect(API.get).toHaveBeenCalledWith(1, { page: 2, history: true });
    expect(
      store.getters['copilotMessages/getMessagesByThreadId'](1).map(
        item => item.message.content
      )
    ).toEqual(['Older', 'Stream complete']);
    expect(store.getters['copilotMessages/getMessagesByThreadId'](2)).toEqual([
      message(30, 2, 'Other chat'),
    ]);
  });
});
