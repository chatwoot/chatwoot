import * as amplitude from '@amplitude/analytics-browser';

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

    amplitude.init(this.analyticsToken, {
      defaultTracking: false,
    });
    this.analytics = amplitude;
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
    this.analytics.setUserId(`user-${this.user.id.toString()}`);

    const identifyEvent = new amplitude.Identify();
    identifyEvent.set('email', this.user.email);
    identifyEvent.set('name', this.user.name);
    identifyEvent.set('avatar', this.user.avatar_url);
    this.analytics.identify(identifyEvent);

    const { accounts, account_id: accountId } = this.user;
    const [currentAccount] = accounts.filter(
      account => account.id === accountId
    );
    if (currentAccount) {
      const groupId = `account-${currentAccount.id.toString()}`;

      this.analytics.setGroup('company', groupId);

      const groupIdentify = new amplitude.Identify();
      groupIdentify.set('name', currentAccount.name);
      this.analytics.groupIdentify('company', groupId, groupIdentify);
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
    this.analytics.track(eventName, properties);
  }

  /**
   * Track the page views
   * @function
   * @param {string} pageName - Page name
   * @param {Object} [properties={}] - Page view properties
   */
  page(pageName, properties = {}) {
    if (!this.analytics) {
      return;
    }

    this.analytics.track('$pageview', { pageName, ...properties });
  }
}

// This object is shared across, the init is called in app/javascript/entrypoints/dashboard.js
export default new AnalyticsHelper(window.analyticsConfig);
