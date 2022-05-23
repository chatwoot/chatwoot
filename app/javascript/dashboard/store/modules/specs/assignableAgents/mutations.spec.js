import { mutations, types } from '../../assignableAgents';
import agentsData from './fixtures';

describe('#mutations', () => {
  describe('#SET_ASSIGNABLE_AGENTS', () => {
    it('updates assignable agents to records', () => {
      const state = { records: [] };
      mutations[types.SET_ASSIGNABLE_AGENTS](state, [...agentsData]);
      expect(state.records).toEqual(agentsData);
    });
  });

  describe('#SET_ASSIGNABLE_AGENTS', () => {
    it('updates assignable agents to records', () => {
      const state = { uiFlags: {} };
      mutations[types.SET_ASSIGNABLE_AGENTS_UI_FLAGS](state, {
        isFetching: true,
      });
      expect(state.uiFlags).toEqual({ isFetching: true });
    });
  });

  describe('#SET_ASSIGNABLE_AGENTS', () => {
    it('clears assignable agent records', () => {
      const state = { records: [{ id: 1 }] };
      mutations[types.CLEAR_ASSIGNABLE_AGENTS](state);
      expect(state.records).toEqual([]);
    });
  });
});
