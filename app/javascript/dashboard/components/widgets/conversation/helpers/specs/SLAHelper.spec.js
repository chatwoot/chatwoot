import { evaluateSLAStatus } from '../SLAHelper';

beforeEach(() => {
  jest
    .spyOn(Date, 'now')
    .mockImplementation(() => new Date('2024-01-01T00:00:00Z').getTime());
});

afterEach(() => {
  jest.restoreAllMocks();
});

describe('SLAHelper', () => {
  describe('evaluateSLAStatus', () => {
    it('returns an empty object when sla or chat is not present', () => {
      expect(evaluateSLAStatus(null, null)).toEqual({
        type: '',
        threshold: '',
        icon: '',
        isSlaMissed: false,
      });
    });

    // Case when FRT SLA is missed
    it('correctly identifies a missed FRT SLA', () => {
      const appliedSla = {
        sla_first_response_time_threshold: 600,
        sla_next_response_time_threshold: 1200,
        sla_resolution_time_threshold: 1800,
        created_at: 1704066540,
      };
      const chatMissed = {
        first_reply_created_at: 0,
        waiting_since: 0,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, chatMissed)).toEqual({
        type: 'FRT',
        threshold: '1m',
        icon: 'flame',
        isSlaMissed: true,
      });
    });

    // Case when FRT SLA is not missed
    it('correctly identifies an FRT SLA not yet breached', () => {
      const appliedSla = {
        sla_first_response_time_threshold: 600,
        sla_next_response_time_threshold: 1200,
        sla_resolution_time_threshold: 1800,
        created_at: 1704066660,
      };
      const chatNotMissed = {
        first_reply_created_at: 0,
        waiting_since: 0,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, chatNotMissed)).toEqual({
        type: 'FRT',
        threshold: '1m',
        icon: 'alarm',
        isSlaMissed: false,
      });
    });

    // Case when NRT SLA is missed
    it('correctly identifies a missed NRT SLA', () => {
      const appliedSla = {
        sla_first_response_time_threshold: 600,
        sla_next_response_time_threshold: 1200,
        sla_resolution_time_threshold: 1800,
        created_at: 1704065200,
      };
      const chatMissed = {
        first_reply_created_at: 1704066200,
        waiting_since: 1704065940,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, chatMissed)).toEqual({
        type: 'NRT',
        threshold: '1m',
        icon: 'flame',
        isSlaMissed: true,
      });
    });

    // Case when NRT SLA is not missed
    it('correctly identifies an NRT SLA not yet breached', () => {
      const appliedSla = {
        sla_first_response_time_threshold: 600,
        sla_next_response_time_threshold: 1200,
        sla_resolution_time_threshold: 1800,
        created_at: 1704065200 - 2000,
      };
      const chatNotMissed = {
        first_reply_created_at: 1704066200,
        waiting_since: 1704066060,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, chatNotMissed)).toEqual({
        type: 'NRT',
        threshold: '1m',
        icon: 'alarm',
        isSlaMissed: false,
      });
    });

    // Case when RT SLA is missed
    it('correctly identifies a missed RT SLA', () => {
      const appliedSla = {
        sla_first_response_time_threshold: 600,
        sla_next_response_time_threshold: 1200,
        sla_resolution_time_threshold: 1800,
        created_at: 1704065340,
      };
      const chatMissed = {
        first_reply_created_at: 1704066200,
        waiting_since: 0,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, chatMissed)).toEqual({
        type: 'RT',
        threshold: '1m',
        icon: 'flame',
        isSlaMissed: true,
      });
    });

    // Case when RT SLA is not missed
    it('correctly identifies an RT SLA not yet breached', () => {
      const appliedSla = {
        sla_first_response_time_threshold: 600,
        sla_next_response_time_threshold: 1200,
        sla_resolution_time_threshold: 1800,
        created_at: 1704065460,
      };
      const chatNotMissed = {
        first_reply_created_at: 1704066200,
        waiting_since: 0,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, chatNotMissed)).toEqual({
        type: 'RT',
        threshold: '1m',
        icon: 'alarm',
        isSlaMissed: false,
      });
    });
  });
});
