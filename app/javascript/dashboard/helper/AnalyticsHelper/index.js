import posthog from 'posthog-js';

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

    posthog.init(this.analyticsToken, {
      api_host: 'https://app.posthog.com',
      capture_pageview: false,
      persistence: 'localStorage+cookie',
    });
    this.analytics = posthog;
  }

  /**
   * Identify the user
   * @function
   * @param {Object} user - User object
   */
  identify(user) {
    if (!this.analytics || !user) {
      return;
    }

    this.user = user;
    this.analytics.identify(this.user.id.toString(), {
      email: this.user.email,
      name: this.user.name,
      avatar: this.user.avatar_url,
    });

    const { accounts, account_id: accountId } = this.user;
    const [currentAccount] = accounts.filter(
      account => account.id === accountId
    );
    if (currentAccount) {
      this.analytics.group('company', currentAccount.id.toString(), {
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
    this.analytics.capture(eventName, properties);
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

    this.analytics.capture('$pageview', params);
  }
}

// This object is shared across, the init is called in app/javascript/entrypoints/dashboard.js
export default new AnalyticsHelper(window.analyticsConfig);
