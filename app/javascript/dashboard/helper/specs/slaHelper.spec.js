import { evaluateSLAStatus } from '../slaHelper';

describe('#SLA Helpers', () => {
  const currentTimestamp = 1700000000; // Fixed timestamp for testing

  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(currentTimestamp * 1000);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  describe('evaluateSLAStatus', () => {
    describe('when inputs are invalid', () => {
      it('returns empty status when appliedSla is null', () => {
        const result = evaluateSLAStatus({ appliedSla: null, chat: {} });
        expect(result).toEqual({
          type: '',
          threshold: '',
          icon: '',
          isSlaMissed: false,
        });
      });

      it('returns empty status when chat is null', () => {
        const result = evaluateSLAStatus({ appliedSla: {}, chat: null });
        expect(result).toEqual({
          type: '',
          threshold: '',
          icon: '',
          isSlaMissed: false,
        });
      });
    });

    describe('FRT (First Response Time)', () => {
      it('returns FRT status when first reply not made and within threshold', () => {
        const appliedSla = { sla_frt_due_at: currentTimestamp + 3600 }; // 1 hour from now
        const chat = { first_reply_created_at: null, status: 'open' };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.type).toBe('FRT');
        expect(result.threshold).toBe('1h');
        expect(result.icon).toBe('alarm');
        expect(result.isSlaMissed).toBe(false);
      });

      it('returns missed FRT status when threshold is exceeded', () => {
        const appliedSla = { sla_frt_due_at: currentTimestamp - 1800 }; // 30 min ago
        const chat = { first_reply_created_at: null, status: 'open' };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.type).toBe('FRT');
        expect(result.threshold).toBe('30m');
        expect(result.icon).toBe('flame');
        expect(result.isSlaMissed).toBe(true);
      });

      it('does not return FRT when first reply already made', () => {
        const appliedSla = { sla_frt_due_at: currentTimestamp + 3600 };
        const chat = {
          first_reply_created_at: currentTimestamp - 1000,
          status: 'open',
        };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.type).not.toBe('FRT');
      });
    });

    describe('NRT (Next Response Time)', () => {
      it('returns NRT status when waiting for response and within threshold', () => {
        const appliedSla = { sla_nrt_due_at: currentTimestamp + 1800 }; // 30 min from now
        const chat = {
          first_reply_created_at: currentTimestamp - 7200,
          waiting_since: currentTimestamp - 600,
          status: 'open',
        };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.type).toBe('NRT');
        expect(result.threshold).toBe('30m');
        expect(result.icon).toBe('alarm');
        expect(result.isSlaMissed).toBe(false);
      });

      it('returns missed NRT status when threshold is exceeded', () => {
        const appliedSla = { sla_nrt_due_at: currentTimestamp - 900 }; // 15 min ago
        const chat = {
          first_reply_created_at: currentTimestamp - 7200,
          waiting_since: currentTimestamp - 2700,
          status: 'open',
        };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.type).toBe('NRT');
        expect(result.threshold).toBe('15m');
        expect(result.icon).toBe('flame');
        expect(result.isSlaMissed).toBe(true);
      });

      it('does not return NRT when not waiting for response', () => {
        const appliedSla = { sla_nrt_due_at: currentTimestamp + 1800 };
        const chat = {
          first_reply_created_at: currentTimestamp - 7200,
          waiting_since: null,
          status: 'open',
        };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.type).not.toBe('NRT');
      });

      it('does not return NRT when first reply not made', () => {
        const appliedSla = { sla_nrt_due_at: currentTimestamp + 1800 };
        const chat = {
          first_reply_created_at: null,
          waiting_since: currentTimestamp - 600,
          status: 'open',
        };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.type).not.toBe('NRT');
      });
    });

    describe('RT (Resolution Time)', () => {
      it('returns RT status when conversation is open and within threshold', () => {
        const appliedSla = { sla_rt_due_at: currentTimestamp + 7200 }; // 2 hours from now
        const chat = {
          first_reply_created_at: currentTimestamp - 3600,
          status: 'open',
        };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.type).toBe('RT');
        expect(result.threshold).toBe('2h');
        expect(result.icon).toBe('alarm');
        expect(result.isSlaMissed).toBe(false);
      });

      it('returns missed RT status when threshold is exceeded', () => {
        const appliedSla = { sla_rt_due_at: currentTimestamp - 3600 }; // 1 hour ago
        const chat = {
          first_reply_created_at: currentTimestamp - 7200,
          status: 'open',
        };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.type).toBe('RT');
        expect(result.threshold).toBe('1h');
        expect(result.icon).toBe('flame');
        expect(result.isSlaMissed).toBe(true);
      });

      it('does not return RT when conversation is resolved', () => {
        const appliedSla = { sla_rt_due_at: currentTimestamp + 7200 };
        const chat = {
          first_reply_created_at: currentTimestamp - 3600,
          status: 'resolved',
        };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.type).toBe('');
      });
    });

    describe('priority selection', () => {
      it('returns most urgent SLA when multiple are active', () => {
        const appliedSla = {
          sla_frt_due_at: currentTimestamp + 7200, // 2h - less urgent
          sla_nrt_due_at: currentTimestamp + 1800, // 30m - most urgent
          sla_rt_due_at: currentTimestamp + 3600, // 1h
        };
        const chat = {
          first_reply_created_at: null,
          waiting_since: currentTimestamp - 600,
          status: 'open',
        };

        const result = evaluateSLAStatus({ appliedSla, chat });

        // FRT is selected because first_reply_created_at is null
        // NRT is not checked when first_reply_created_at is null
        expect(result.type).toBe('RT');
        expect(result.threshold).toBe('1h');
      });

      it('returns most urgent missed SLA over upcoming SLA', () => {
        const appliedSla = {
          sla_nrt_due_at: currentTimestamp - 300, // 5m overdue - most urgent by absolute value
          sla_rt_due_at: currentTimestamp + 3600, // 1h remaining
        };
        const chat = {
          first_reply_created_at: currentTimestamp - 7200,
          waiting_since: currentTimestamp - 2100,
          status: 'open',
        };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.type).toBe('NRT');
        expect(result.isSlaMissed).toBe(true);
      });
    });

    describe('time formatting', () => {
      it('formats time in days and hours', () => {
        const appliedSla = { sla_rt_due_at: currentTimestamp + 90000 }; // 25 hours
        const chat = { status: 'open' };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.threshold).toBe('1d 1h');
      });

      it('formats time less than a minute as 1m', () => {
        const appliedSla = { sla_frt_due_at: currentTimestamp + 30 }; // 30 seconds
        const chat = { first_reply_created_at: null, status: 'open' };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.threshold).toBe('1m');
      });

      it('formats months correctly', () => {
        const appliedSla = {
          sla_rt_due_at: currentTimestamp + 2592000 + 86400,
        }; // 1 month + 1 day
        const chat = { status: 'open' };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result.threshold).toBe('1mo 1d');
      });
    });

    describe('empty status scenarios', () => {
      it('returns empty when no SLA thresholds are set', () => {
        const appliedSla = {};
        const chat = { status: 'open' };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result).toEqual({
          type: '',
          threshold: '',
          icon: '',
          isSlaMissed: false,
        });
      });

      it('returns empty when all conditions are met', () => {
        const appliedSla = {
          sla_frt_due_at: currentTimestamp + 3600,
          sla_nrt_due_at: currentTimestamp + 1800,
          sla_rt_due_at: currentTimestamp + 7200,
        };
        const chat = {
          first_reply_created_at: currentTimestamp - 3600, // FRT already hit
          waiting_since: null, // Not waiting, so NRT not applicable
          status: 'resolved', // RT not applicable
        };

        const result = evaluateSLAStatus({ appliedSla, chat });

        expect(result).toEqual({
          type: '',
          threshold: '',
          icon: '',
          isSlaMissed: false,
        });
      });
    });
  });
});
