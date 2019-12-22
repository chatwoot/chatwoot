/* eslint arrow-body-style: ["error", "always"] */

const endPoints = {
  resetPassword: {
    url: 'auth/password',
  },
  register: {
    url: 'api/v1/accounts.json',
  },
  validityCheck: {
    url: '/auth/validate_token',
  },
  logout: {
    url: 'auth/sign_out',
  },

  me: {
    url: 'api/v1/conversations.json',
    params: { type: 0, page: 1 },
  },

  getInbox: {
    url: 'api/v1/conversations.json',
    params: { inbox_id: null },
  },

  fetchLabels: {
    url: 'api/v1/labels.json',
  },

  fetchInboxes: {
    url: 'api/v1/inboxes.json',
  },

  createChannel(channel, channelParams) {
    return {
      url: `api/v1/callbacks/register_${channel}_page.json`,
      params: channelParams,
    };
  },

  addAgentsToChannel: {
    url: 'api/v1/inbox_members.json',
    params: { user_ids: [], inbox_id: null },
  },

  fetchFacebookPages: {
    url: 'api/v1/callbacks/get_facebook_pages.json',
    params: { omniauth_token: '' },
  },

  reports: {
    account(metric, from, to) {
      return {
        url: `/api/v1/reports/account?metric=${metric}&since=${from}&to=${to}`,
      };
    },
    accountSummary(accountId, from, to) {
      return {
        url: `/api/v1/reports/${accountId}/account_summary?since=${from}&to=${to}`,
      };
    },
  },

  subscriptions: {
    get() {
      return {
        url: '/api/v1/subscriptions',
      };
    },
  },

  inbox: {
    delete(id) {
      return {
        url: `/api/v1/inboxes/${id}`,
      };
    },
    agents: {
      get(id) {
        return {
          url: `/api/v1/inbox_members/${id}.json`,
        };
      },
      post() {
        return {
          url: '/api/v1/inbox_members.json',
        };
      },
    },
  },
};

export default page => {
  return endPoints[page];
};
