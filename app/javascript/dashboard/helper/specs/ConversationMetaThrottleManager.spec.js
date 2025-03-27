import ConversationMetaThrottleManager from '../ConversationMetaThrottleManager';

describe('ConversationMetaThrottleManager', () => {
  beforeEach(() => {
    // Reset the lastUpdatedTime before each test
    ConversationMetaThrottleManager.lastUpdatedTime = null;
  });

  describe('shouldThrottle', () => {
    it('returns false when lastUpdatedTime is not set', () => {
      expect(ConversationMetaThrottleManager.shouldThrottle()).toBe(false);
    });

    it('returns true when time difference is less than threshold', () => {
      ConversationMetaThrottleManager.markUpdate();
      expect(ConversationMetaThrottleManager.shouldThrottle()).toBe(true);
    });

    it('returns false when time difference is more than threshold', () => {
      ConversationMetaThrottleManager.lastUpdatedTime = new Date(
        Date.now() - 11000
      );
      expect(ConversationMetaThrottleManager.shouldThrottle()).toBe(false);
    });

    it('respects custom threshold value', () => {
      ConversationMetaThrottleManager.lastUpdatedTime = new Date(
        Date.now() - 5000
      );
      expect(ConversationMetaThrottleManager.shouldThrottle(3000)).toBe(false);
      expect(ConversationMetaThrottleManager.shouldThrottle(6000)).toBe(true);
    });
  });
});
