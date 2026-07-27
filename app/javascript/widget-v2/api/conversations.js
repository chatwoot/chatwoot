import { client } from './client';

export const fetchConversations = ({ section, page = 1 }) =>
  client
    .get('/api/v2/widget/conversations', { params: { section, page } })
    .then(response => response.data);

export const fetchConversation = displayId =>
  client
    .get(`/api/v2/widget/conversations/${displayId}`)
    .then(response => response.data);

export const createConversation = ({
  section,
  content,
  contact,
  referrerUrl,
}) =>
  client
    .post('/api/v2/widget/conversations', {
      section,
      contact,
      message: {
        content,
        referer_url: referrerUrl,
        timestamp: new Date().toString(),
      },
    })
    .then(response => response.data);

export const resolveConversation = displayId =>
  client.post(`/api/v2/widget/conversations/${displayId}/resolve`);

export const updateLastSeen = displayId =>
  client.post(`/api/v2/widget/conversations/${displayId}/update_last_seen`);

export const toggleTyping = (displayId, typingStatus) =>
  client.post(`/api/v2/widget/conversations/${displayId}/toggle_typing`, {
    typing_status: typingStatus,
  });
