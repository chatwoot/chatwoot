import { emitter } from 'shared/helpers/mitt';
import { mutations } from '..';
import { BUS_EVENTS } from '../../../../../shared/constants/busEvents';
import types from '../../../mutation-types';

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    emit: vi.fn(),
  },
}));

describe('UPDATE_CONVERSATION', () => {
  let state;

  beforeEach(() => {
    state = {
      allConversations: [],
      selectedChatId: null,
    };
    vi.clearAllMocks();
  });

  it('should add new conversation if not found', () => {
    const conversation = {
      id: 123,
      title: 'Test',
      updated_at: Math.floor(Date.now() / 1000),
    };

    mutations[types.UPDATE_CONVERSATION](state, conversation);

    expect(state.allConversations).toHaveLength(1);
    expect(state.allConversations[0]).toEqual(conversation);
  });

  it('should skip update if incoming data is older', () => {
    const oldTimestamp = Math.floor(new Date('2024-01-01').getTime() / 1000);
    const newTimestamp = Math.floor(new Date('2024-01-02').getTime() / 1000);

    const existing = {
      id: 123,
      title: 'Original',
      updated_at: newTimestamp,
      messages: ['msg1'],
    };

    const update = {
      id: 123,
      title: 'Updated',
      updated_at: oldTimestamp,
    };

    state.allConversations = [existing];
    mutations[types.UPDATE_CONVERSATION](state, update);

    expect(state.allConversations[0]).toEqual(existing);
  });

  it('should update properties except messages', () => {
    const timestamp1 = Math.floor(new Date('2024-01-01').getTime() / 1000);
    const timestamp2 = Math.floor(new Date('2024-01-02').getTime() / 1000);

    const existing = {
      id: 123,
      title: 'Original',
      status: 'draft',
      updated_at: timestamp1,
      messages: ['msg1'],
    };

    const update = {
      id: 123,
      title: 'Updated',
      status: 'published',
      updated_at: timestamp2,
      messages: ['msg2'],
    };

    state.allConversations = [existing];
    mutations[types.UPDATE_CONVERSATION](state, update);

    expect(state.allConversations[0]).toEqual({
      id: 123,
      title: 'Updated',
      status: 'published',
      updated_at: timestamp2,
      messages: ['msg1'],
    });
  });

  it('should emit events when updating selected conversation', () => {
    const existing = {
      id: 123,
      title: 'Original',
      status: 'draft',
      updated_at: Math.floor(Date.now() / 1000),
      messages: ['msg1'],
    };

    const conversation = {
      id: 123,
      updated_at: Math.floor(Date.now() / 1000) + 1,
    };

    state.selectedChatId = 123;
    state.allConversations = [existing];

    mutations[types.UPDATE_CONVERSATION](state, conversation);

    expect(emitter.emit).toHaveBeenCalledWith(
      BUS_EVENTS.FETCH_LABEL_SUGGESTIONS
    );
    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.SCROLL_TO_MESSAGE);
  });

  it('should not emit events when updating non-selected conversation', () => {
    const conversation = {
      id: 123,
      updated_at: Math.floor(Date.now() / 1000),
    };

    state.selectedChatId = '456';
    mutations[types.UPDATE_CONVERSATION](state, conversation);

    expect(emitter.emit).not.toHaveBeenCalled();
  });
});
