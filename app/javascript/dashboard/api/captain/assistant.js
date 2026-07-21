/* global axios */
import ApiClient from '../ApiClient';

// Viewer's UTC offset in hours, matching the reports API convention so the
// backend can anchor calendar ranges to the viewer's day.
const getTimezoneOffset = () => -new Date().getTimezoneOffset() / 60;

class CaptainAssistant extends ApiClient {
  constructor() {
    super('captain/assistants', { accountScoped: true });
  }

  get({ page = 1, searchKey } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        searchKey,
      },
    });
  }

  playground({ assistantId, messageContent, messageHistory }) {
    return axios.post(`${this.url}/${assistantId}/playground`, {
      message_content: messageContent,
      message_history: messageHistory,
    });
  }

  getStats({ assistantId, range }) {
    return axios.get(`${this.url}/${assistantId}/stats`, {
      params: { range, timezone_offset: getTimezoneOffset() },
    });
  }

  getSummary({ assistantId, range }) {
    return axios.get(`${this.url}/${assistantId}/summary`, {
      params: { range, timezone_offset: getTimezoneOffset() },
    });
  }

  getDrilldown({ assistantId, metric, range, page, signal }) {
    const requestConfig = {
      params: {
        metric,
        range,
        timezone_offset: getTimezoneOffset(),
        page,
      },
    };
    if (signal) requestConfig.signal = signal;

    return axios.get(`${this.url}/${assistantId}/drilldown`, requestConfig);
  }
}

export default new CaptainAssistant();
