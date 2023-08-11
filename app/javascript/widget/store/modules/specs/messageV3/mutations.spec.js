import { mutations } from '../../messageV3/mutations';
import Vue from 'vue';

describe('mutations', () => {
  let state;

  beforeEach(() => {
    state = {
      messages: {
        byId: {},
        allIds: [],
        uiFlags: {
          byId: {},
        },
      },
    };
  });

  test('addMessagesEntry', () => {
    mutations.addMessagesEntry(state, {
      messages: [{ id: '1', content: 'Hello' }],
    });
    expect(state.messages.byId['1'].content).toBe('Hello');
  });

  test('addMessageIds', () => {
    state.messages.allIds.push('1');
    mutations.addMessageIds(state, {
      messages: [{ id: '2' }, { id: '3' }],
    });
    expect(state.messages.allIds).toEqual(['1', '2', '3']);
  });

  test('updateMessageEntry', () => {
    Vue.set(state.messages.byId, '1', { id: '1', content: 'Hello' });
    mutations.updateMessageEntry(state, { id: '1', content: 'Updated Hello' });
    expect(state.messages.byId['1'].content).toBe('Updated Hello');
  });

  test('removeMessageEntry', () => {
    Vue.set(state.messages.byId, '1', { id: '1', content: 'Hello' });
    mutations.removeMessageEntry(state, '1');
    expect(state.messages.byId['1']).toBeUndefined();
  });

  test('removeMessageId', () => {
    state.messages.allIds = ['1', '2', '3'];
    mutations.removeMessageId(state, '2');
    expect(state.messages.allIds).toEqual(['1', '3']);
  });

  test('setMessageUIFlag', () => {
    mutations.setMessageUIFlag(state, {
      messageId: '1',
      uiFlags: { isLoading: true },
    });
    expect(state.messages.uiFlags.byId['1'].isLoading).toBe(true);
  });
});
