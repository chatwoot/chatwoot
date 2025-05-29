import { describe, it, expect, vi, beforeEach } from 'vitest';
import SummaryReportsAPI from 'dashboard/api/summaryReports';
import store, { initialState } from '../summaryReports';

vi.mock('dashboard/api/summaryReports', () => ({
  default: {
    getInboxReports: vi.fn(),
    getAgentReports: vi.fn(),
    getTeamReports: vi.fn(),
  },
}));

describe('Summary Reports Store', () => {
  let commit;

  beforeEach(() => {
    // Reset all mocks before each test
    vi.clearAllMocks();
    commit = vi.fn();
  });

  describe('Initial State', () => {
    it('should have the correct initial state structure', () => {
      expect(initialState).toEqual({
        inboxSummaryReports: [],
        agentSummaryReports: [],
        teamSummaryReports: [],
        uiFlags: {
          isFetchingInboxSummaryReports: false,
          isFetchingAgentSummaryReports: false,
          isFetchingTeamSummaryReports: false,
        },
      });
    });
  });

  describe('Getters', () => {
    const state = {
      inboxSummaryReports: [{ id: 1 }],
      agentSummaryReports: [{ id: 2 }],
      teamSummaryReports: [{ id: 3 }],
      uiFlags: { isFetchingInboxSummaryReports: true },
    };

    it('should return inbox summary reports', () => {
      expect(store.getters.getInboxSummaryReports(state)).toEqual([{ id: 1 }]);
    });

    it('should return agent summary reports', () => {
      expect(store.getters.getAgentSummaryReports(state)).toEqual([{ id: 2 }]);
    });

    it('should return team summary reports', () => {
      expect(store.getters.getTeamSummaryReports(state)).toEqual([{ id: 3 }]);
    });

    it('should return UI flags', () => {
      expect(store.getters.getUIFlags(state)).toEqual({
        isFetchingInboxSummaryReports: true,
      });
    });
  });

  describe('Mutations', () => {
    it('should set inbox summary report', () => {
      const state = { ...initialState };
      const data = [{ id: 1 }];

      store.mutations.setInboxSummaryReport(state, data);
      expect(state.inboxSummaryReports).toEqual(data);
    });

    it('should set agent summary report', () => {
      const state = { ...initialState };
      const data = [{ id: 2 }];

      store.mutations.setAgentSummaryReport(state, data);
      expect(state.agentSummaryReports).toEqual(data);
    });

    it('should set team summary report', () => {
      const state = { ...initialState };
      const data = [{ id: 3 }];

      store.mutations.setTeamSummaryReport(state, data);
      expect(state.teamSummaryReports).toEqual(data);
    });

    it('should merge UI flags with existing flags', () => {
      const state = {
        uiFlags: { flag1: true, flag2: false },
      };
      const newFlags = { flag2: true, flag3: true };

      store.mutations.setUIFlags(state, newFlags);
      expect(state.uiFlags).toEqual({
        flag1: true,
        flag2: true,
        flag3: true,
      });
    });
  });

  describe('Actions', () => {
    describe('fetchInboxSummaryReports', () => {
      it('should fetch inbox reports successfully', async () => {
        const params = { date: '2025-01-01' };
        const mockResponse = {
          data: [{ report_id: 1, report_name: 'Test' }],
        };

        SummaryReportsAPI.getInboxReports.mockResolvedValue(mockResponse);

        await store.actions.fetchInboxSummaryReports({ commit }, params);

        expect(commit).toHaveBeenCalledWith('setUIFlags', {
          isFetchingInboxSummaryReports: true,
        });
        expect(SummaryReportsAPI.getInboxReports).toHaveBeenCalledWith(params);
        expect(commit).toHaveBeenCalledWith('setInboxSummaryReport', [
          { reportId: 1, reportName: 'Test' },
        ]);
        expect(commit).toHaveBeenCalledWith('setUIFlags', {
          isFetchingInboxSummaryReports: false,
        });
      });

      it('should handle errors gracefully', async () => {
        SummaryReportsAPI.getInboxReports.mockRejectedValue(
          new Error('API Error')
        );

        await store.actions.fetchInboxSummaryReports({ commit }, {});

        expect(commit).toHaveBeenCalledWith('setUIFlags', {
          isFetchingInboxSummaryReports: false,
        });
      });
    });

    describe('fetchAgentSummaryReports', () => {
      it('should fetch agent reports successfully', async () => {
        const params = { agentId: 123 };
        const mockResponse = {
          data: [{ agent_id: 123, agent_name: 'Test Agent' }],
        };

        SummaryReportsAPI.getAgentReports.mockResolvedValue(mockResponse);

        await store.actions.fetchAgentSummaryReports({ commit }, params);

        expect(commit).toHaveBeenCalledWith('setUIFlags', {
          isFetchingAgentSummaryReports: true,
        });
        expect(SummaryReportsAPI.getAgentReports).toHaveBeenCalledWith(params);
        expect(commit).toHaveBeenCalledWith('setAgentSummaryReport', [
          { agentId: 123, agentName: 'Test Agent' },
        ]);
        expect(commit).toHaveBeenCalledWith('setUIFlags', {
          isFetchingAgentSummaryReports: false,
        });
      });
    });

    describe('fetchTeamSummaryReports', () => {
      it('should fetch team reports successfully', async () => {
        const params = { teamId: 456 };
        const mockResponse = {
          data: [{ team_id: 456, team_name: 'Test Team' }],
        };

        SummaryReportsAPI.getTeamReports.mockResolvedValue(mockResponse);

        await store.actions.fetchTeamSummaryReports({ commit }, params);

        expect(commit).toHaveBeenCalledWith('setUIFlags', {
          isFetchingTeamSummaryReports: true,
        });
        expect(SummaryReportsAPI.getTeamReports).toHaveBeenCalledWith(params);
        expect(commit).toHaveBeenCalledWith('setTeamSummaryReport', [
          { teamId: 456, teamName: 'Test Team' },
        ]);
        expect(commit).toHaveBeenCalledWith('setUIFlags', {
          isFetchingTeamSummaryReports: false,
        });
      });
    });
  });
});
