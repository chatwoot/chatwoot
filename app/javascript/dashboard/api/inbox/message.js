/* eslint no-console: 0 */
/* global axios */
import ApiClient from '../ApiClient';

export const buildCreatePayload = ({
  message,
  isPrivate,
  contentAttributes,
  echoId,
  files,
  ccEmails = '',
  bccEmails = '',
  toEmails = '',
  templateParams,
}) => {
  let payload;
  if (files && files.length !== 0) {
    payload = new FormData();
    if (message) {
      payload.append('content', message);
    }
    files.forEach(file => {
      payload.append('attachments[]', file);
    });
    payload.append('private', isPrivate);
    if (templateParams) {
      payload.append(
        'stringified_template_params',
        JSON.stringify(templateParams)
      );
    }
    payload.append('echo_id', echoId);
    payload.append('cc_emails', ccEmails);
    payload.append('bcc_emails', bccEmails);

    if (toEmails) {
      payload.append('to_emails', toEmails);
    }
    if (contentAttributes) {
      payload.append('content_attributes', JSON.stringify(contentAttributes));
    }
  } else {
    payload = {
      content: message,
      private: isPrivate,
      echo_id: echoId,
      content_attributes: contentAttributes,
      cc_emails: ccEmails,
      bcc_emails: bccEmails,
      to_emails: toEmails,
      template_params: templateParams,
    };
  }
  return payload;
};

class MessageApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  create({
    conversationId,
    message,
    private: isPrivate,
    contentAttributes,
    echo_id: echoId,
    files,
    ccEmails = '',
    bccEmails = '',
    toEmails = '',
    templateParams,
  }) {
    return axios({
      method: 'post',
      url: `${this.url}/${conversationId}/messages`,
      data: buildCreatePayload({
        message,
        isPrivate,
        contentAttributes,
        echoId,
        files,
        ccEmails,
        bccEmails,
        toEmails,
        templateParams,
      }),
    });
  }

  delete(conversationID, messageId) {
    return axios.delete(`${this.url}/${conversationID}/messages/${messageId}`);
  }

  retry(conversationID, messageId) {
    return axios.post(
      `${this.url}/${conversationID}/messages/${messageId}/retry`
    );
  }

  getPreviousMessages({ conversationId, after, before, before_timestamp }) {
    let params = { before };
    if (after && Number(after) !== Number(before)) {
      params.after = after;
    }
    if (before_timestamp) {
      params = { before_timestamp };
    }
    return axios.get(`${this.url}/${conversationId}/messages`, { params });
  }

  translateMessage(conversationId, messageId, targetLanguage) {
    return axios.post(
      `${this.url}/${conversationId}/messages/${messageId}/translate`,
      {
        target_language: targetLanguage,
      }
    );
  }

  forward(conversationId, messageId, { toEmails, comment }) {
    return axios.post(
      `${this.url}/${conversationId}/messages/${messageId}/forward`,
      {
        forward: {
          to_emails: toEmails,
          comment: comment,
        },
      }
    );
  }
}

export default new MessageApi();
