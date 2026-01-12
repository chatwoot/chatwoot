/* global axios */

import ApiClient from './ApiClient';

class AgentActivity extends ApiClient {
  constructor() {
    super('summary_reports/agent_activity', {
      accountScoped: true,
      apiVersion: 'v2',
    });
  }

  getSummary({
    since,
    until,
    teamIds,
    userIds,
    inboxIds,
    hideInactive,
    timezoneOffset,
  }) {
    return axios.get(this.url, {
      params: {
        since,
        until,
        'team_ids[]': teamIds,
        'user_ids[]': userIds,
        'inbox_ids[]': inboxIds,
        hide_inactive: hideInactive,
        timezone_offset: timezoneOffset,
      },
    });
  }
}

export default new AgentActivity();
