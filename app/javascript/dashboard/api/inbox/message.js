/* eslint no-console: 0 */
/* global axios */
import ApiClient from '../ApiClient';

export const buildCreatePayload = ({
  message,
  isPrivate,
  contentAttributes,
  contentType,
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
    payload.append('echo_id', echoId);
    payload.append('cc_emails', ccEmails);
    payload.append('bcc_emails', bccEmails);

    if (toEmails) {
      payload.append('to_emails', toEmails);
    }
    if (contentAttributes) {
      console.log(
        '🔥 buildCreatePayload: Serializing content_attributes for FormData:',
        contentAttributes
      );
      console.log(
        '🔥 buildCreatePayload: Images in content_attributes:',
        contentAttributes.images?.length || 'NO IMAGES'
      );
      const serializedContentAttributes = JSON.stringify(contentAttributes);
      console.log(
        '🔥 buildCreatePayload: Serialized content_attributes length:',
        serializedContentAttributes.length
      );
      payload.append('content_attributes', serializedContentAttributes);
    }
    if (contentType) {
      payload.append('content_type', contentType);
    }
  } else {
    payload = {
      content: message,
      private: isPrivate,
      echo_id: echoId,
      content_attributes: contentAttributes,
      content_type: contentType,
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

  create(params) {
    console.log('🔥 MessageApi.create called with params:', params);

    // Handle both camelCase and snake_case property names
    const {
      conversationId,
      message,
      private: isPrivate,
      contentAttributes,
      content_attributes,
      content_type,
      echo_id: echoId,
      files,
      ccEmails = '',
      bccEmails = '',
      toEmails = '',
      templateParams,
    } = params;

    console.log(
      '🔥 MessageApi extracted content_attributes:',
      content_attributes
    );
    console.log(
      '🔥 MessageApi extracted contentAttributes:',
      contentAttributes
    );

    // Use content_attributes if contentAttributes is not provided (for Vuex compatibility)
    const finalContentAttributes = contentAttributes || content_attributes;
    const finalContentType = content_type;
    const finalEchoId = echoId || params.echo_id;

    console.log(
      '🔥 MessageApi finalContentAttributes:',
      finalContentAttributes
    );
    console.log(
      '🔥 MessageApi finalContentAttributes images:',
      finalContentAttributes?.images?.length || 'NO IMAGES'
    );

    const payload = buildCreatePayload({
      message,
      isPrivate,
      contentAttributes: finalContentAttributes,
      contentType: finalContentType,
      echoId: finalEchoId,
      files,
      ccEmails,
      bccEmails,
      toEmails,
      templateParams,
    });

    console.log('🔥 MessageApi final payload:', payload);
    console.log(
      '🔥 MessageApi payload content_attributes:',
      payload.content_attributes
    );
    console.log(
      '🔥 MessageApi payload images:',
      payload.content_attributes?.images?.length || 'NO IMAGES'
    );

    return axios({
      method: 'post',
      url: `${this.url}/${conversationId}/messages`,
      data: payload,
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

  getPreviousMessages({ conversationId, after, before }) {
    const params = { before };
    if (after && Number(after) !== Number(before)) {
      params.after = after;
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
}

export default new MessageApi();
