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

  // The inbox payload carries `capabilities`, which the build that served it decides, so a
  // key fetched from a different request cannot vouch for these rows. The index sends the
  // key for the body it just built; without one, this response came from a build that does
  // not, and it is not cached at all.
  // eslint-disable-next-line class-methods-use-this
  get usesResponseBoundCacheKey() {
    return true;
  }

  // eslint-disable-next-line class-methods-use-this
  cacheKeyFromResponse(response) {
    return response?.data?.cache_key ?? null;
  }

  // Keeps the locally cached inbox fresh on connection-status changes without bumping
  // the cache key (so it never triggers a full refetch). Silent if IDB is unavailable.
  async updateCachedProviderConnection(id, providerConnection) {
    try {
      await this.dataManager.initDb();
      await this.dataManager.update({
        modelName: this.cacheModelName,
        id,
        data: { provider_connection: providerConnection },
      });
    } catch {
      // Ignore
    }
  }

  // Whether WhatsApp knows this phone, asked through the inbox's paired session.
  // Answers `{ jid, exists }`. Advisory: the server gives up early rather than hold the
  // request, since the caller only shows a hint.
  onWhatsapp(inboxId, phoneNumber) {
    return axios.post(`${this.url}/${inboxId}/on_whatsapp`, {
      phone_number: phoneNumber,
      advisory: true,
    });
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

  getAgentBotObservers(inboxId) {
    return axios.get(`${this.url}/${inboxId}/agent_bot_observers`);
  }

  addAgentBotObserver(inboxId, botId) {
    return axios.post(`${this.url}/${inboxId}/agent_bot_observers`, {
      agent_bot: botId,
    });
  }

  removeAgentBotObserver(inboxId, botId) {
    return axios.delete(`${this.url}/${inboxId}/agent_bot_observers/${botId}`);
  }

  syncTemplates(inboxId) {
    return axios.post(`${this.url}/${inboxId}/sync_templates`);
  }

  getMessageTemplates(inboxId, params = {}, config = {}) {
    return axios.get(`${this.url}/${inboxId}/message_templates`, {
      ...config,
      params,
    });
  }

  updateWhatsappBusinessManagementToken(inboxId, businessManagementToken) {
    return axios.put(
      `${this.url}/${inboxId}/whatsapp_business_management_token`,
      {
        business_management_token: businessManagementToken,
      }
    );
  }

  createCSATTemplate(inboxId, template) {
    return axios.post(`${this.url}/${inboxId}/csat_template`, {
      template,
    });
  }

  getCSATTemplateStatus(inboxId) {
    return axios.get(`${this.url}/${inboxId}/csat_template`);
  }

  analyzeCSATTemplateUtility(inboxId, template) {
    return axios.post(`${this.url}/${inboxId}/csat_template/analyze`, {
      template,
    });
  }

  resetSecret(inboxId) {
    return axios.post(`${this.url}/${inboxId}/reset_secret`);
  }

  linkCSATTemplate(inboxId, template) {
    return axios.post(`${this.url}/${inboxId}/csat_template/link`, {
      template,
    });
  }

  getAvailableCSATTemplates(inboxId) {
    return axios.get(
      `${this.url}/${inboxId}/csat_template/available_templates`
    );
  }

  setupChannelProvider(inboxId) {
    return axios.post(`${this.url}/${inboxId}/setup_channel_provider`);
  }

  requestPairingCode(inboxId) {
    return axios.post(`${this.url}/${inboxId}/request_pairing_code`);
  }

  disconnectChannelProvider(inboxId) {
    return axios.post(`${this.url}/${inboxId}/disconnect_channel_provider`);
  }

  convertProvider(inboxId, { provider, providerConfig }) {
    return axios.post(`${this.url}/${inboxId}/convert_provider`, {
      provider,
      provider_config: providerConfig,
    });
  }

  rotateHmacToken(inboxId) {
    return axios.post(`${this.url}/${inboxId}/rotate_hmac_token`);
  }

  getWhatsappCallingStatus(inboxId) {
    return axios.get(`${this.url}/${inboxId}/whatsapp_calling_status`);
  }

  enableWhatsappCalling(inboxId) {
    return axios.post(`${this.url}/${inboxId}/enable_whatsapp_calling`);
  }

  getWhatsappCallHours(inboxId) {
    return axios.get(`${this.url}/${inboxId}/whatsapp_call_hours`);
  }

  applyWhatsappCallHours(inboxId) {
    return axios.patch(`${this.url}/${inboxId}/whatsapp_call_hours`);
  }

  disableWhatsappCalling(inboxId) {
    return axios.post(`${this.url}/${inboxId}/disable_whatsapp_calling`);
  }

  setInboundCalls(inboxId, enabled) {
    return axios.post(`${this.url}/${inboxId}/set_inbound_calls`, {
      inbound_calls_enabled: enabled,
    });
  }

  setCallRecording(inboxId, { recordingEnabled, transcriptionEnabled }) {
    return axios.post(`${this.url}/${inboxId}/set_call_recording`, {
      recording_enabled: recordingEnabled,
      transcription_enabled: transcriptionEnabled,
    });
  }

  setCallRouting(
    inboxId,
    {
      ringStrategy,
      ringStepSeconds,
      assigneeRingsFirst,
      callCooldownSeconds,
      businessHoursCallsEnabled,
    }
  ) {
    return axios.patch(`${this.url}/${inboxId}/call_routing`, {
      ring_strategy: ringStrategy,
      ring_step_seconds: ringStepSeconds,
      assignee_rings_first: assigneeRingsFirst,
      call_cooldown_seconds: callCooldownSeconds,
      business_hours_calls_enabled: businessHoursCallsEnabled,
    });
  }

  // kind: 'greeting' | 'unanswered'; only 'unanswered' carries a ring time
  setCallAnnouncement(inboxId, kind, { enabled, message, timeoutSeconds }) {
    return axios.patch(`${this.url}/${inboxId}/call_announcements/${kind}`, {
      enabled,
      message,
      timeout_seconds: timeoutSeconds,
    });
  }
}

export default new Inboxes();
