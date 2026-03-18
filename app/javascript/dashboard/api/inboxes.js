/* global axios */
import CacheEnabledApiClient from './CacheEnabledApiClient';

class Inboxes extends CacheEnabledApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'inbox';
  }

  getCampaigns(inboxId) {
    return axios.get(`${this.url}/${inboxId}/campaigns`);
  }

  deleteInboxAvatar(inboxId) {
    return axios.delete(`${this.url}/${inboxId}/avatar`);
  }

  getAgentBot(inboxId) {
    return axios.get(`${this.url}/${inboxId}/agent_bot`);
  }

  setAgentBot(inboxId, botId) {
    return axios.post(`${this.url}/${inboxId}/set_agent_bot`, {
      agent_bot: botId,
    });
  }

  setSurvey(inboxId, surveyId) {
    return axios.post(`${this.url}/${inboxId}/set_survey`, {
      survey_id: surveyId,
    });
  }

  syncTemplates(inboxId) {
    return axios.post(`${this.url}/${inboxId}/sync_templates`);
  }

  getInbox(inboxId) {
    return axios.get(`${this.url}/${inboxId}`);
  }

  createCSATTemplate(inboxId, template) {
    return axios.post(`${this.url}/${inboxId}/csat_template`, {
      template,
    });
  }

  getCSATTemplateStatus(inboxId) {
    return axios.get(`${this.url}/${inboxId}/csat_template`);
  }

  getInbox(inboxId) {
    return axios.get(`${this.url}/${inboxId}`);
  }

  // Message Templates API
  getMessageTemplates(inboxId, params = {}) {
    const queryParams = new URLSearchParams();
    if (params.limit) queryParams.append('limit', params.limit);
    if (params.after) queryParams.append('after', params.after);
    if (params.before) queryParams.append('before', params.before);
    if (params.fetchAll) queryParams.append('fetch_all', 'true');

    const queryString = queryParams.toString();
    const url = queryString
      ? `${this.url}/${inboxId}/message_templates?${queryString}`
      : `${this.url}/${inboxId}/message_templates`;

    return axios.get(url);
  }

  createMessageTemplate(inboxId, template) {
    return axios.post(`${this.url}/${inboxId}/message_templates`, { template });
  }

  getMessageTemplateStatus(inboxId, templateName) {
    return axios.get(`${this.url}/${inboxId}/message_templates/${templateName}`);
  }

  deleteMessageTemplate(inboxId, templateName, templateId = null) {
    const params = templateId ? { template_id: templateId } : {};
    return axios.delete(`${this.url}/${inboxId}/message_templates/${templateName}`, { params });
  }
}

export default new Inboxes();
