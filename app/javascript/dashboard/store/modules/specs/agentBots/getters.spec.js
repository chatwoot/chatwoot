import { getters } from '../../agentBots';
import { agentBotRecords } from './fixtures';

describe('#getters', () => {
  it('getBots', () => {
    const state = { records: agentBotRecords };
    expect(getters.getBots(state)).toEqual(agentBotRecords);
  });

  it('getBot', () => {
    const state = { records: agentBotRecords };
    expect(getters.getBot(state)(11)).toEqual(agentBotRecords[0]);
  });

  it('getObserverBots', () => {
    const state = {
      records: agentBotRecords,
      agentBotObservers: { 5: [12, 99] },
    };
    expect(getters.getObserverBots(state)(5)).toEqual([agentBotRecords[1]]);
    expect(getters.getObserverBots(state)(6)).toEqual([]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
      isUpdating: false,
      isDeleting: false,
    });
  });
});
