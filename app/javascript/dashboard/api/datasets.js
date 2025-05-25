/* global axios */
import ApiClient from './ApiClient';

class DatasetAPI extends ApiClient {
  constructor() {
    super('dataset_configurations', { accountScoped: true });
  }

  // Get all dataset configurations
  getAll() {
    return axios.get(`${this.baseUrl()}/dataset_configurations`);
  }

  // Get a specific dataset configuration
  get(id) {
    return axios.get(`${this.baseUrl()}/dataset_configurations/${id}`);
  }

  // Create a new dataset configuration
  create(datasetData) {
    return axios.post(`${this.baseUrl()}/dataset_configurations`, {
      dataset_configuration: datasetData
    });
  }

  // Update a dataset configuration
  update(id, datasetData) {
    return axios.put(`${this.baseUrl()}/dataset_configurations/${id}`, {
      dataset_configuration: datasetData
    });
  }

  // Delete a dataset configuration
  delete(id) {
    return axios.delete(`${this.baseUrl()}/dataset_configurations/${id}`);
  }

  // Test connection for a dataset configuration
  testConnection(id) {
    return axios.post(`${this.baseUrl()}/dataset_configurations/${id}/test_connection`);
  }

  // Get available pixels for a dataset configuration
  getPixels(id) {
    return axios.get(`${this.baseUrl()}/dataset_configurations/${id}/pixels`);
  }

  // Generate access token for a dataset configuration
  generateToken(id, params) {
    return axios.post(`${this.baseUrl()}/dataset_configurations/${id}/generate_token`, params);
  }

  // Get available inboxes for dataset mapping
  getAvailableInboxes(platform = null) {
    const params = platform ? { platform } : {};
    return axios.get(`${this.baseUrl()}/dataset_configurations/available_inboxes`, { params });
  }

  // Inbox Dataset Mappings
  getInboxMappings(inboxId) {
    return axios.get(`${this.baseUrl()}/inboxes/${inboxId}/dataset_mappings`);
  }

  createInboxMapping(inboxId, mappingData) {
    return axios.post(`${this.baseUrl()}/inboxes/${inboxId}/dataset_mappings`, {
      inbox_dataset_mapping: mappingData
    });
  }

  updateInboxMapping(inboxId, mappingId, mappingData) {
    return axios.put(`${this.baseUrl()}/inboxes/${inboxId}/dataset_mappings/${mappingId}`, {
      inbox_dataset_mapping: mappingData
    });
  }

  deleteInboxMapping(inboxId, mappingId) {
    return axios.delete(`${this.baseUrl()}/inboxes/${inboxId}/dataset_mappings/${mappingId}`);
  }

  getAvailableDatasets(inboxId) {
    return axios.get(`${this.baseUrl()}/inboxes/${inboxId}/dataset_mappings/available_datasets`);
  }

  // Platform-specific helpers
  getFacebookPixels(accountId = null) {
    const params = accountId ? { account_id: accountId } : {};
    return axios.get(`${this.baseUrl()}/dataset_configurations/pixels`, { 
      params: { platform: 'facebook', ...params }
    });
  }

  getInstagramPixels(accountId = null) {
    const params = accountId ? { account_id: accountId } : {};
    return axios.get(`${this.baseUrl()}/dataset_configurations/pixels`, { 
      params: { platform: 'instagram', ...params }
    });
  }

  getMetaPixels(accountId = null) {
    const params = accountId ? { account_id: accountId } : {};
    return axios.get(`${this.baseUrl()}/dataset_configurations/pixels`, { 
      params: { platform: 'meta', ...params }
    });
  }

  generateFacebookToken(pixelId) {
    return axios.post(`${this.baseUrl()}/dataset_configurations/generate_token`, {
      platform: 'facebook',
      pixel_id: pixelId
    });
  }

  generateInstagramToken(pixelId) {
    return axios.post(`${this.baseUrl()}/dataset_configurations/generate_token`, {
      platform: 'instagram',
      pixel_id: pixelId
    });
  }

  generateMetaToken(pixelId) {
    return axios.post(`${this.baseUrl()}/dataset_configurations/generate_token`, {
      platform: 'meta',
      pixel_id: pixelId
    });
  }

  // Validation helpers
  validatePixelId(pixelId, platform) {
    return axios.post(`${this.baseUrl()}/dataset_configurations/validate_pixel`, {
      pixel_id: pixelId,
      platform: platform
    });
  }

  validateAccessToken(accessToken, pixelId, platform) {
    return axios.post(`${this.baseUrl()}/dataset_configurations/validate_token`, {
      access_token: accessToken,
      pixel_id: pixelId,
      platform: platform
    });
  }

  // Bulk operations
  bulkEnable(datasetIds) {
    return axios.post(`${this.baseUrl()}/dataset_configurations/bulk_enable`, {
      dataset_ids: datasetIds
    });
  }

  bulkDisable(datasetIds) {
    return axios.post(`${this.baseUrl()}/dataset_configurations/bulk_disable`, {
      dataset_ids: datasetIds
    });
  }

  bulkDelete(datasetIds) {
    return axios.post(`${this.baseUrl()}/dataset_configurations/bulk_delete`, {
      dataset_ids: datasetIds
    });
  }

  // Analytics and reporting
  getDatasetStats(id, dateRange = null) {
    const params = dateRange ? { date_range: dateRange } : {};
    return axios.get(`${this.baseUrl()}/dataset_configurations/${id}/stats`, { params });
  }

  getAccountStats(dateRange = null) {
    const params = dateRange ? { date_range: dateRange } : {};
    return axios.get(`${this.baseUrl()}/dataset_configurations/account_stats`, { params });
  }

  exportDatasetData(id, format = 'csv', dateRange = null) {
    const params = { 
      format,
      ...(dateRange ? { date_range: dateRange } : {})
    };
    return axios.get(`${this.baseUrl()}/dataset_configurations/${id}/export`, { 
      params,
      responseType: 'blob'
    });
  }
}

export default new DatasetAPI();
