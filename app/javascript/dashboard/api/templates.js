/* global axios */

import ApiClient from './ApiClient';

class TemplatesAPI extends ApiClient {
  constructor() {
    super('templates', { accountScoped: true });
  }

  get({ searchKey, category, channel, tags } = {}) {
    const params = new URLSearchParams();
    if (searchKey) params.append('search', searchKey);
    if (category) params.append('category', category);
    if (channel) params.append('channel', channel);
    if (tags) params.append('tags', tags);

    const url = params.toString()
      ? `${this.url}?${params.toString()}`
      : this.url;
    return axios.get(url);
  }

  create(templateData) {
    // Extract content blocks and channel mappings to send as separate params
    const { contentBlocks, channelMappings, ...templateFields } = templateData;

    return axios.post(this.url, {
      template: templateFields,
      content_blocks: contentBlocks,
      channel_mappings: channelMappings,
    });
  }

  update(id, templateData) {
    // Extract content blocks and channel mappings to send as separate params
    const { contentBlocks, channelMappings, ...templateFields } = templateData;

    return axios.patch(`${this.url}/${id}`, {
      template: templateFields,
      content_blocks: contentBlocks,
      channel_mappings: channelMappings,
    });
  }

  render(templateId, parameters, channelType) {
    return axios.post(`${this.url}/${templateId}/render_template`, {
      parameters,
      channel_type: channelType,
    });
  }

  sendMessage(conversationId, templateId, parameters) {
    return axios.post(
      `${this.baseUrl()}/conversations/${conversationId}/messages/from_template`,
      {
        template_id: templateId,
        parameters,
      }
    );
  }

  testTemplate(templateId, parameters, channelType) {
    return axios.post(`${this.url}/${templateId}/test`, {
      parameters,
      channel_type: channelType,
    });
  }

  createFromAppleMessage(payload) {
    return axios.post(`${this.url}/from_apple_message`, {
      messageType: payload.messageType,
      messageData: payload.messageData,
      templateName: payload.templateName,
      category: payload.category,
      description: payload.description,
      tags: payload.tags || [],
    });
  }
}

export default new TemplatesAPI();
