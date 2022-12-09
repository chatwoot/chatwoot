import { AnalyticsBrowser } from '@june-so/analytics-next';

class AnalyticsHelper {
  constructor({ token: analyticsToken } = {}) {
    this.analyticsToken = analyticsToken;
    this.analytics = null;
    this.user = {};
  }

  async init() {
    if (!this.analyticsToken) {
      return;
    }

    let [analytics] = await AnalyticsBrowser.load({
      writeKey: this.analyticsToken,
    });
    this.analytics = analytics;
  }

  identify(user) {
    if (!this.analytics) {
      return;
    }
    this.user = user;
    this.analytics.identify(this.user.email, {
      userId: this.user.id,
      email: this.user.email,
      name: this.user.name,
      avatar: this.user.avatar_url,
    });

    const { accounts, account_id: accountId } = this.user;
    const [currentAccount] = accounts.filter(
      account => account.id === accountId
    );
    if (currentAccount) {
      this.analytics.group(currentAccount.id, this.user.id, {
        name: currentAccount.name,
      });
    }
  }

  track(eventName, properties = {}) {
    if (!this.analytics) {
      return;
    }

    this.analytics.track({
      userId: this.user.id,
      event: eventName,
      properties,
    });
  }

  page(params) {
    if (!this.analytics) {
      return;
    }

    this.analytics.page(params);
  }
}

export * as ANALYTICS_EVENTS from './events';

export default new AnalyticsHelper(window.analyticsConfig);
