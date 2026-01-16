/* global axios */
import ApiClient from './ApiClient';

class EvolutionAPI extends ApiClient {
  constructor() {
    super('evolution', { accountScoped: true });
  }

  // Check if Evolution API is enabled
  getStatus() {
    return axios.get(`${this.url}/status`);
  }

  // Create a new Evolution-backed inbox (Baileys)
  createInbox(inboxData) {
    return axios.post(`${this.url}/inboxes`, {
      evolution_inbox: inboxData,
    });
  }

  // Get Chatwoot integration settings for an inbox
  getChatwootSettings(inboxId) {
    return axios.get(`${this.url}/inboxes/${inboxId}/chatwoot`);
  }

  // Update Chatwoot integration settings
  updateChatwootSettings(inboxId, settings) {
    return axios.put(`${this.url}/inboxes/${inboxId}/chatwoot`, settings);
  }

  // Get connection state for an inbox
  getConnectionState(inboxId) {
    return axios.get(`${this.url}/inboxes/${inboxId}/connection`);
  }

  // Get QR code for Baileys inbox connection
  getQRCode(inboxId) {
    return axios.get(`${this.url}/inboxes/${inboxId}/qrcode`);
  }

  // Enable Chatwoot integration (after QR scan for Baileys)
  enableIntegration(inboxId) {
    return axios.post(`${this.url}/inboxes/${inboxId}/enable_integration`);
  }

  // Restart Evolution instance
  restartInstance(inboxId) {
    return axios.post(`${this.url}/inboxes/${inboxId}/restart`);
  }

  // Logout (disconnect) Evolution instance from WhatsApp
  logoutInstance(inboxId) {
    return axios.post(`${this.url}/inboxes/${inboxId}/logout`);
  }

  // Refresh connection (reconnect for Baileys)
  refreshInstance(inboxId) {
    return axios.post(`${this.url}/inboxes/${inboxId}/refresh`);
  }

  // Get instance settings (reject calls, groups ignore, always online, etc.)
  getInstanceSettings(inboxId) {
    return axios.get(`${this.url}/inboxes/${inboxId}/instance_settings`);
  }

  // Update instance settings
  updateInstanceSettings(inboxId, settings) {
    return axios.put(
      `${this.url}/inboxes/${inboxId}/instance_settings`,
      settings
    );
  }

  // Re-authenticate Evolution integration with current user's token
  reauthenticate(inboxId) {
    return axios.post(`${this.url}/inboxes/${inboxId}/reauthenticate`);
  }
}

export default new EvolutionAPI();
