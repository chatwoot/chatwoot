import types from '../../../mutation-types';
import { mutations } from '../../agentBots';
import { agentBotRecords } from './fixtures';

describe('#mutations', () => {
  describe('#SET_AGENT_BOT_UI_FLAG', () => {
    it('set uiFlags', () => {
      const state = { uiFlags: { isFetchingItem: false } };
      mutations[types.SET_AGENT_BOT_UI_FLAG](state, { isFetchingItem: true });
      expect(state.uiFlags.isFetchingItem).toEqual(true);
    });
  });
  describe('#SET_AGENT_BOTS', () => {
    it('set agent bot records', () => {
      const state = { records: [] };
      mutations[types.SET_AGENT_BOTS](state, agentBotRecords);
      expect(state.records).toEqual(agentBotRecords);
    });
  });
  describe('#ADD_AGENT_BOT', () => {
    it('push newly created bot to the store', () => {
      const state = { records: [agentBotRecords[0]] };
      mutations[types.ADD_AGENT_BOT](state, agentBotRecords[1]);
      expect(state.records).toEqual([agentBotRecords[0], agentBotRecords[1]]);
    });
  });
  describe('#EDIT_AGENT_BOT', () => {
    it('update agent bot record', () => {
      const state = { records: [agentBotRecords[0]] };
      mutations[types.EDIT_AGENT_BOT](state, {
        id: 11,
        name: 'agent-bot-11',
      });
      expect(state.records[0].name).toEqual('agent-bot-11');
    });
  });
  describe('#DELETE_AGENT_BOT', () => {
    it('delete agent bot record', () => {
      const state = { records: [agentBotRecords[0]] };
      mutations[types.DELETE_AGENT_BOT](state, agentBotRecords[0]);
      expect(state.records).toEqual([agentBotRecords[0]]);
    });
  });
});
