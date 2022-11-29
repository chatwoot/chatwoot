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
  profileUpdate: {
    url: '/api/v1/profile',
  },
  availabilityUpdate: {
    url: '/api/v1/profile/availability',
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
    url(accountId) {
      return `api/v1/accounts/${accountId}/callbacks/facebook_pages.json`;
    },
    params: { omniauth_token: '' },
  },

  deleteAvatar: {
    url: '/api/v1/profile/avatar',
  },

  setActiveAccount: {
    url: '/api/v1/profile/set_active_account',
  },
};

export default page => {
  return endPoints[page];
};
