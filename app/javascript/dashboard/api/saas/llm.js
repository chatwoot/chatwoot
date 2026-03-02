/* global axios */
import ApiClient from '../ApiClient';

class LlmAPI extends ApiClient {
  constructor() {
    super('llm', { accountScoped: true, saas: true });
  }

  getModels() {
    return axios.get(`${this.url}/models`);
  }

  getHealth() {
    return axios.get(`${this.url}/health`);
  }

  /**
   * Send a chat completion request.
   * When stream=true, returns { request_id, stream: true } — subscribe to LlmChannel for chunks.
   * When stream=false, returns the full LLM response.
   */
  completions({
    model,
    messages,
    stream = true,
    temperature,
    maxTokens,
    feature,
  }) {
    return axios.post(`${this.url}/completions`, {
      model,
      messages,
      stream,
      temperature,
      max_tokens: maxTokens,
      feature,
    });
  }
}

export default new LlmAPI();
