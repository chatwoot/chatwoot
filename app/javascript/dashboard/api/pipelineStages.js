/* global axios */
import ApiClient from './ApiClient';

class PipelineStagesAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  // Label pipeline stages CRUD
  getStages(labelId) {
    return axios.get(`${this.baseUrl()}/labels/${labelId}/pipeline_stages`);
  }

  createStage(labelId, data) {
    return axios.post(`${this.baseUrl()}/labels/${labelId}/pipeline_stages`, {
      pipeline_stage: data,
    });
  }

  updateStage(labelId, stageId, data) {
    return axios.patch(
      `${this.baseUrl()}/labels/${labelId}/pipeline_stages/${stageId}`,
      { pipeline_stage: data }
    );
  }

  deleteStage(labelId, stageId) {
    return axios.delete(
      `${this.baseUrl()}/labels/${labelId}/pipeline_stages/${stageId}`
    );
  }

  reorderStages(labelId, positions) {
    return axios.post(
      `${this.baseUrl()}/labels/${labelId}/pipeline_stages/reorder`,
      { positions }
    );
  }

  // Contact pipeline stages
  getContactStages(contactId) {
    return axios.get(`${this.baseUrl()}/contacts/${contactId}/pipeline_stages`);
  }

  updateContactStage(contactId, assignmentId, pipelineStageId) {
    return axios.patch(
      `${this.baseUrl()}/contacts/${contactId}/pipeline_stages/${assignmentId}`,
      { pipeline_stage_id: pipelineStageId }
    );
  }
}

export default new PipelineStagesAPI();
