/* global axios */
import ApiClient from './ApiClient';

export const buildRecurringScheduledMessagePayload = ({
  content,
  status,
  scheduledAt,
  templateParams,
  attachment,
  removeAttachment,
  recurrenceRule,
} = {}) => {
  if (!attachment) {
    return {
      content,
      status,
      scheduled_at: scheduledAt,
      template_params: templateParams,
      remove_attachment: removeAttachment || undefined,
      recurrence_rule: recurrenceRule,
    };
  }

  const payload = new FormData();
  if (content) payload.append('content', content);
  if (scheduledAt) payload.append('scheduled_at', scheduledAt);
  if (status) payload.append('status', status);
  payload.append('attachment', attachment);
  if (templateParams) {
    payload.append('template_params', JSON.stringify(templateParams));
  }
  if (recurrenceRule) {
    Object.entries(recurrenceRule).forEach(([key, value]) => {
      if (Array.isArray(value)) {
        value.forEach(v =>
          payload.append(`recurrence_rule[${key}][]`, String(v))
        );
      } else {
        payload.append(`recurrence_rule[${key}]`, String(value));
      }
    });
  }

  return payload;
};

class RecurringScheduledMessagesAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  get(conversationId) {
    return axios.get(
      `${this.baseUrl()}/conversations/${conversationId}/recurring_scheduled_messages`
    );
  }

  create(conversationId, payload) {
    return axios({
      method: 'post',
      url: `${this.baseUrl()}/conversations/${conversationId}/recurring_scheduled_messages`,
      data: buildRecurringScheduledMessagePayload(payload),
    });
  }

  update(conversationId, recurringScheduledMessageId, payload) {
    return axios({
      method: 'patch',
      url: `${this.baseUrl()}/conversations/${conversationId}/recurring_scheduled_messages/${recurringScheduledMessageId}`,
      data: buildRecurringScheduledMessagePayload(payload),
    });
  }

  delete(conversationId, recurringScheduledMessageId) {
    return axios.delete(
      `${this.baseUrl()}/conversations/${conversationId}/recurring_scheduled_messages/${recurringScheduledMessageId}`
    );
  }
}

export default new RecurringScheduledMessagesAPI();
