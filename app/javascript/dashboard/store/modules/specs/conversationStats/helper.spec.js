import { describe, it, expect, vi, beforeEach } from 'vitest';
import ConversationMetaThrottleManager from 'dashboard/helper/ConversationMetaThrottleManager';
import { shouldThrottle } from '../../conversationStats';

vi.mock('dashboard/helper/ConversationMetaThrottleManager', () => ({
  default: {
    shouldThrottle: vi.fn(),
  },
}));

describe('shouldThrottle', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('uses normal threshold for accounts with 100 or fewer conversations', () => {
    shouldThrottle(100);
    expect(ConversationMetaThrottleManager.shouldThrottle).toHaveBeenCalledWith(
      2000
    );
  });

  it('uses large account threshold for accounts with more than 100 conversations', () => {
    shouldThrottle(101);
    expect(ConversationMetaThrottleManager.shouldThrottle).toHaveBeenCalledWith(
      10000
    );
  });

  it('returns the throttle value from ConversationMetaThrottleManager', () => {
    ConversationMetaThrottleManager.shouldThrottle.mockReturnValue(true);
    expect(shouldThrottle(50)).toBe(true);

    ConversationMetaThrottleManager.shouldThrottle.mockReturnValue(false);
    expect(shouldThrottle(150)).toBe(false);
  });
});
