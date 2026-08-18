/* global axios */
import ApiClient from '../ApiClient';

const getTimezoneOffset = () => -new Date().getTimezoneOffset() / 60;

class CaptainAssistantStats extends ApiClient {
  constructor() {
    super('captain/assistants', { accountScoped: true });
  }

  getOverview(params) {
    return this.getStats('overview', params);
  }

  getOverviewSummary(params) {
    return this.getStats('overview_summary', params);
  }

  getResolutionFlow(params) {
    return this.getStats('resolution_flow', params);
  }

  getResolutionTrend(params) {
    return this.getStats('resolution_trend', params);
  }

  getStats(endpoint, { assistantId, range, signal }) {
    const requestConfig = {
      params: { range, timezone_offset: getTimezoneOffset() },
    };
    if (signal) requestConfig.signal = signal;

    return axios.get(
      `${this.url}/${assistantId}/stats/${endpoint}`,
      requestConfig
    );
  }
}

export default new CaptainAssistantStats();
