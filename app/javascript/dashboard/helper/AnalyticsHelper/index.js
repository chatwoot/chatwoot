// Analytics disabled - no external tracking connections

export class AnalyticsHelper {
  constructor() {
    this.analytics = null;
    this.user = {};
  }

  async init() {
    // No-op: Analytics disabled
  }

  identify() {
    // No-op: Analytics disabled
  }

  track() {
    // No-op: Analytics disabled
  }

  page() {
    // No-op: Analytics disabled
  }
}

export default new AnalyticsHelper();
