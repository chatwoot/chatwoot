import { evaluateSLAStatus } from '../SLAHelper';

const appliedSla = {
  sla_first_response_time_threshold: 600,
  sla_next_response_time_threshold: 1200,
  sla_resolution_time_threshold: 1800,
  created_at: 1704066600,
  id: 1,
  sla_description: 'SLA description',
  sla_id: 20,
  sla_name: 'SLA name',
  sla_status: 'active',
  updated_at: 1704066600,
  sla_only_during_business_hours: false,
};

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
      expect(evaluateSLAStatus(null, [], null)).toEqual({
        type: '',
        threshold: '',
        icon: '',
        isSlaMissed: false,
      });
    });

    it('correctly identifies a missed FRT SLA', () => {
      const slaEvents = [
        {
          event_type: 'frt',
        },
        {
          event_type: 'nrt',
        },
        {
          event_type: 'rt',
        },
      ];
      const chat = {
        first_reply_created_at: 0,
        waiting_since: 0,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, slaEvents, chat)).toEqual({
        type: 'FRT',
        threshold: '1m',
        icon: 'flame',
        isSlaMissed: true,
      });
    });

    it('correctly identifies an FRT SLA not yet breached', () => {
      const slaEvents = [
        {
          event_type: 'nrt',
        },
        {
          event_type: 'rt',
        },
      ];
      const chat = {
        first_reply_created_at: 0,
        waiting_since: 0,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, slaEvents, chat)).toEqual({
        type: 'FRT',
        threshold: '1m',
        icon: 'alarm',
        isSlaMissed: false,
      });
    });

    it('correctly identifies a missed NRT SLA', () => {
      const slaEvents = [
        {
          event_type: 'frt',
        },
        {
          event_type: 'nrt',
        },
        {
          event_type: 'rt',
        },
      ];
      const chat = {
        first_reply_created_at: 1704066200,
        waiting_since: 1704065940,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, slaEvents, chat)).toEqual({
        type: 'NRT',
        threshold: '1m',
        icon: 'flame',
        isSlaMissed: true,
      });
    });

    it('correctly identifies an NRT SLA not yet breached', () => {
      const slaEvents = [
        {
          event_type: 'frt',
        },
        {
          event_type: 'rt',
        },
      ];
      const chat = {
        first_reply_created_at: 1704066200,
        waiting_since: 1704066060,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, slaEvents, chat)).toEqual({
        type: 'NRT',
        threshold: '1m',
        icon: 'alarm',
        isSlaMissed: false,
      });
    });

    it('correctly identifies a missed RT SLA', () => {
      const slaEvents = [
        {
          event_type: 'frt',
        },
        {
          event_type: 'nrt',
        },
        {
          event_type: 'rt',
        },
      ];
      const chat = {
        first_reply_created_at: 1704066200,
        waiting_since: 0,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, slaEvents, chat)).toEqual({
        type: 'RT',
        threshold: '1m',
        icon: 'flame',
        isSlaMissed: true,
      });
    });

    it('correctly identifies an RT SLA not yet breached', () => {
      const slaEvents = [
        {
          event_type: 'frt',
        },
        {
          event_type: 'nrt',
        },
      ];
      const chat = {
        first_reply_created_at: 1704066200,
        waiting_since: 0,
        status: 'open',
      };
      expect(evaluateSLAStatus(appliedSla, slaEvents, chat)).toEqual({
        type: 'RT',
        threshold: '20m',
        icon: 'alarm',
        isSlaMissed: false,
      });
    });
  });
});
