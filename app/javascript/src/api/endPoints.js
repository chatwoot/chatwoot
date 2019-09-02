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

  conversations(id) {
    return { url: `api/v1/conversations/${id}.json`, params: { before: null } };
  },

  resolveConversation(id) {
    return { url: `api/v1/conversations/${id}/toggle_status.json` };
  },

  sendMessage(conversationId, message) {
    return {
      url: `api/v1/conversations/${conversationId}/messages.json`,
      params: { message },
    };
  },

  addPrivateNote(conversationId, message) {
    return {
      url: `api/v1/conversations/${conversationId}/messages.json?`,
      params: { message, private: 'true' },
    };
  },

  fetchLabels: {
    url: 'api/v1/labels.json',
  },

  fetchInboxes: {
    url: 'api/v1/inboxes.json',
  },

  fetchAgents: {
    url: 'api/v1/agents.json',
  },

  addAgent: {
    url: 'api/v1/agents.json',
  },

  editAgent(id) {
    return { url: `api/v1/agents/${id}` };
  },

  deleteAgent({ id }) {
    return { url: `api/v1/agents/${id}` };
  },

  createEmailChannel(params) {
    return {
      url: `api/v1/email_inboxes.json`,
      params,
    };
  },

  createFBChannel(channel, channelParams) {
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

  assignAgent(conversationId, AgentId) {
    return {
      url: `/api/v1/conversations/${conversationId}/assignments?assignee_id=${AgentId}`,
    };
  },

  fbMarkSeen: {
    url: 'api/v1/facebook_indicators/mark_seen',
  },

  fbTyping(status) {
    return {
      url: `api/v1/facebook_indicators/typing_${status}`,
    };
  },

  markMessageRead(id) {
    return {
      url: `api/v1/conversations/${id}/update_last_seen`,
      params: {
        agent_last_seen_at: null,
      },
    };
  },

  // Canned Response [GET, POST, PUT, DELETE]
  cannedResponse: {
    get() {
      return {
        url: 'api/v1/canned_responses',
      };
    },
    getOne({ id }) {
      return {
        url: `api/v1/canned_responses/${id}`,
      };
    },
    post() {
      return {
        url: 'api/v1/canned_responses',
      };
    },
    put(id) {
      return {
        url: `api/v1/canned_responses/${id}`,
      };
    },
    delete(id) {
      return {
        url: `api/v1/canned_responses/${id}`,
      };
    },
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
