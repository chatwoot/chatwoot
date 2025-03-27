class ConversationMetaThrottleManager {
  constructor() {
    this.lastUpdatedTime = null;
  }

  shouldThrottle(threshold = 10000) {
    if (!this.lastUpdatedTime) {
      return false;
    }

    const currentTime = new Date().getTime();
    const lastUpdatedTime = new Date(this.lastUpdatedTime).getTime();

    if (currentTime - lastUpdatedTime < threshold) {
      return true;
    }
    return false;
  }

  markUpdate() {
    this.lastUpdatedTime = new Date();
  }

  reset() {
    this.lastUpdatedTime = null;
  }
}

export default new ConversationMetaThrottleManager();
