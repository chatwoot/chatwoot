import { ref } from 'vue';
import { useTrialStatus } from '../useTrialStatus';
import { useAccount } from 'dashboard/composables/useAccount';

vi.mock('dashboard/composables/useAccount');

const withAttributes = attributes => {
  useAccount.mockReturnValue({
    currentAccount: ref({ custom_attributes: attributes }),
  });
  return useTrialStatus();
};

describe('useTrialStatus', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-10-18T12:00:00Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('reports an active trial that will convert', () => {
    const status = withAttributes({
      subscription_status: 'trialing',
      trial_ends_at: '2026-10-21T12:00:00Z',
    });

    expect(status.isTrialing.value).toBe(true);
    expect(status.trialCancelsAt.value).toBeNull();
    expect(status.trialDaysLeft.value).toBe(3);
    expect(status.isTrialEndingSoon.value).toBe(true);
  });

  it('reports a cancelled trial, which Stripe keeps as trialing until it ends', () => {
    const status = withAttributes({
      subscription_status: 'trialing',
      trial_ends_at: '2026-10-21T12:00:00Z',
      subscription_cancels_on: '2026-10-21T12:00:00Z',
    });

    expect(status.isTrialing.value).toBe(true);
    expect(status.trialCancelsAt.value).toEqual(
      new Date('2026-10-21T12:00:00Z')
    );
    expect(status.isTrialEndingSoon.value).toBe(false);
  });

  it('ignores a cancel date outside a trial', () => {
    const status = withAttributes({
      subscription_status: 'active',
      subscription_cancels_on: '2026-10-21T12:00:00Z',
    });

    expect(status.isTrialing.value).toBe(false);
    expect(status.trialCancelsAt.value).toBeNull();
  });
});
