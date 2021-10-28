import { API } from 'widget/helpers/axios';

const buildUrl = endPoint =>
  `/api/v1/widget/${endPoint}${window.location.search}`;

/*
 *  Refer: https://www.chatwoot.com/developers/api#tag/Conversations-API
 */

export default {
  async createWithMessage(content, contact) {
    const referrerURL = window.referrerURL || '';

    return API.post(buildUrl('conversations'), {
      contact: {
        name: contact.fullName,
        email: contact.emailAddress,
      },
      message: {
        content,
        timestamp: new Date().toString(),
        referer_url: referrerURL,
      },
    });
  },

  async get() {
    return API.get(buildUrl('conversations'));
  },

  async toggleTypingIn({ typingStatus, conversationId }) {
    return API.post(buildUrl(`conversations/${conversationId}/toggle_typing`), {
      typing_status: typingStatus,
    });
  },

  async setUserLastSeenIn({ lastSeen, conversationId }) {
    return API.post(
      buildUrl(`conversations/${conversationId}/update_last_seen`),
      {
        contact_last_seen_at: lastSeen,
      }
    );
  },

  async sendEmailTranscriptIn({ email, conversationId }) {
    return API.post(buildUrl(`conversations/${conversationId}/transcript`), {
      email,
    });
  },
};
