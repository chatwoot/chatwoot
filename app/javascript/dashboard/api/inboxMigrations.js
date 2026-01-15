/* global axios */
import ApiClient from './ApiClient';

class InboxMigrationsAPI extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  /**
   * Get list of migrations for an inbox
   * @param {number} inboxId - Source inbox ID
   * @returns {Promise}
   */
  getMigrations(inboxId) {
    return axios.get(`${this.url}/${inboxId}/migrations`);
  }

  /**
   * Get a specific migration status
   * @param {number} inboxId - Source inbox ID
   * @param {number} migrationId - Migration ID
   * @returns {Promise}
   */
  getMigration(inboxId, migrationId) {
    return axios.get(`${this.url}/${inboxId}/migrations/${migrationId}`);
  }

  /**
   * Get preview of what would be migrated
   * @param {number} inboxId - Source inbox ID
   * @param {number} destinationInboxId - Destination inbox ID
   * @returns {Promise}
   */
  getPreview(inboxId, destinationInboxId) {
    return axios.get(`${this.url}/${inboxId}/migrations/preview`, {
      params: { destination_inbox_id: destinationInboxId },
    });
  }

  /**
   * Get list of eligible destination inboxes
   * @param {number} inboxId - Source inbox ID
   * @returns {Promise}
   */
  getEligibleDestinations(inboxId) {
    return axios.get(`${this.url}/${inboxId}/migrations/eligible_destinations`);
  }

  /**
   * Start a new migration
   * @param {number} inboxId - Source inbox ID
   * @param {number} destinationInboxId - Destination inbox ID
   * @returns {Promise}
   */
  createMigration(inboxId, destinationInboxId) {
    return axios.post(`${this.url}/${inboxId}/migrations`, {
      inbox_migration: {
        destination_inbox_id: destinationInboxId,
      },
    });
  }

  /**
   * Cancel a queued migration
   * @param {number} inboxId - Source inbox ID
   * @param {number} migrationId - Migration ID
   * @returns {Promise}
   */
  cancelMigration(inboxId, migrationId) {
    return axios.post(
      `${this.url}/${inboxId}/migrations/${migrationId}/cancel`
    );
  }
}

export default new InboxMigrationsAPI();
