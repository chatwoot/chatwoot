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
};

export default page => {
  return endPoints[page];
};
