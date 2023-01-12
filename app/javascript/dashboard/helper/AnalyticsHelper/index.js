import { AnalyticsBrowser } from '@june-so/analytics-next';

/**
 * AnalyticsHelper class to initialize and track user analytics
 * @class AnalyticsHelper
 */
export class AnalyticsHelper {
  /**
   * @constructor
   * @param {Object} [options={}] - options for analytics
   * @param {string} [options.token] - analytics token
   */
  constructor({ token: analyticsToken } = {}) {
    this.analyticsToken = analyticsToken;
    this.analytics = null;
    this.user = {};
  }

  /**
   * Initialize analytics
   * @function
   * @async
   */
  async init() {
    if (!this.analyticsToken) {
      return;
    }

    let [analytics] = await AnalyticsBrowser.load({
      writeKey: this.analyticsToken,
    });
    this.analytics = analytics;
  }

  /**
   * Identify the user
   * @function
   * @param {Object} user - User object
   */
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

  /**
   * Track any event
   * @function
   * @param {string} eventName - event name
   * @param {Object} [properties={}] - event properties
   */
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

  /**
   * Track the page views
   * @function
   * @param {Object} params - Page view properties
   */
  page(params) {
    if (!this.analytics) {
      return;
    }

    this.analytics.page(params);
  }
}

// This object is shared across, the init is called in app/javascript/packs/application.js
export default new AnalyticsHelper(window.analyticsConfig);
