import { getters } from '../../inboxAssignableAgents';
import agentsData from './fixtures';

describe('#getters', () => {
  it('getAssignableAgents', () => {
    const state = {
      records: {
        1: [agentsData[0]],
      },
    };
    expect(getters.getAssignableAgents(state)(1)).toEqual([agentsData[0]]);
  });

  it('keeps AI assignees scoped to the type-aware assignment list', () => {
    const agentBot = {
      id: 1,
      name: 'Agent Bot',
      assignee_type: 'AgentBot',
    };
    const captain = {
      id: 2,
      name: 'Captain',
      assignee_type: 'Captain::Assistant',
    };
    const state = {
      records: {
        1: [agentBot, captain, agentsData[0]],
        '1:with_ai_assignees': [agentBot, captain, agentsData[0]],
      },
    };

    expect(getters.getAssignableAgents(state)(1)).toEqual([agentsData[0]]);
    expect(
      getters.getAssignableAgents(state)(1, {
        includeAIAssignees: true,
      })
    ).toEqual([agentBot, captain, agentsData[0]]);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: false,
    });
  });
});
