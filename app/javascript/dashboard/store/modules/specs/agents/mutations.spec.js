import * as types from '../../../mutation-types';
import { mutations } from '../../agents';

describe('#mutations', () => {
  describe('#SET_AGENTS', () => {
    it('set agent records', () => {
      const state = { records: [] };
      mutations[types.default.SET_AGENTS](state, [
        { id: 1, name: 'Agent1', email: 'agent1@chatwoot.com' },
      ]);
      expect(state.records).toEqual([
        {
          id: 1,
          name: 'Agent1',
          email: 'agent1@chatwoot.com',
        },
      ]);
    });
  });

  describe('#ADD_AGENT', () => {
    it('push newly created agent data to the store', () => {
      const state = {
        records: [{ id: 1, name: 'Agent1', email: 'agent1@chatwoot.com' }],
      };
      mutations[types.default.ADD_AGENT](state, {
        id: 2,
        name: 'Agent2',
        email: 'agent2@chatwoot.com',
      });
      expect(state.records).toEqual([
        { id: 1, name: 'Agent1', email: 'agent1@chatwoot.com' },
        { id: 2, name: 'Agent2', email: 'agent2@chatwoot.com' },
      ]);
    });
  });

  describe('#EDIT_AGENT', () => {
    it('sets allMessagesLoaded flag if payload is empty', () => {
      const state = {
        records: [{ id: 1, name: 'Agent1', email: 'agent1@chatwoot.com' }],
      };
      mutations[types.default.EDIT_AGENT](state, {
        id: 1,
        name: 'Agent2',
        email: 'agent2@chatwoot.com',
      });
      expect(state.records).toEqual([
        { id: 1, name: 'Agent2', email: 'agent2@chatwoot.com' },
      ]);
    });
  });

  describe('#DELETE_AGENT', () => {
    it('sets allMessagesLoaded flag if payload is empty', () => {
      const state = {
        records: [{ id: 1, name: 'Agent1', email: 'agent1@chatwoot.com' }],
      };
      mutations[types.default.DELETE_AGENT](state, 1);
      expect(state.records).toEqual([]);
    });
  });
});
