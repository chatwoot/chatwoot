/* global axios */
import ApiClient from './ApiClient';

const getTimeOffset = () => -new Date().getTimezoneOffset() / 60;

class CustomReportsAPI extends ApiClient {
  constructor() {
    super('custom_reports', { accountScoped: true, apiVersion: 'v2' });
  }

  getCustomAgentOverviewReports({
    since,
    until,
    businessHours,
    selectedLabel,
    selectedInbox,
  } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
      timezone_offset: getTimeOffset(),
    };

    if (selectedInbox) {
      params.inboxes = [selectedInbox.id];
    }

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.get(`${this.url}/agents_overview`, { params });
  }

  getCustomAgentConversationStatesReports({
    since,
    until,
    businessHours,
    selectedLabel,
    selectedInbox,
  } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
      timezone_offset: getTimeOffset(),
    };

    if (selectedInbox) {
      params.inboxes = [selectedInbox.id];
    }

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.get(`${this.url}/agent_wise_conversation_states`, { params });
  }

  getCustomLabelConversationStatesReports({
    since,
    until,
    businessHours,
    selectedLabel,
    selectedInbox,
  } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
      timezone_offset: getTimeOffset(),
    };

    if (selectedInbox) {
      params.inboxes = [selectedInbox.id];
    }

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.get(`${this.url}/label_wise_conversation_states`, { params });
  }

  getBotFlows() {
    return axios.get(`${this.url}/bot_flows`);
  }

  getCustomBotAnalyticsOverviewReports({
    since,
    until,
    selectedLabel,
    flowId,
  }) {
    const params = {
      since,
      until,
      business_hours: false,
      timezone_offset: getTimeOffset(),
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    if (flowId) {
      params.flow_id = flowId;
    }

    return axios.get(`${this.url}/bot_analytics_overview`, { params });
  }

  getCustomLiveChatAnalyticsOverviewReports({ since, until, selectedLabel }) {
    const params = {
      since,
      until,
      business_hours: false,
      timezone_offset: getTimeOffset(),
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.get(`${this.url}/live_chat_analytics_overview`, { params });
  }

  getCustomLiveChatOtherMetricsReports({ since, until, selectedLabel }) {
    const params = {
      since,
      until,
      business_hours: false,
      timezone_offset: getTimeOffset(),
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.get(`${this.url}/live_chat_other_metrics_overview`, {
      params,
    });
  }

  getCustomBotAnalyticsSalesOverviewReports({ since, until, selectedLabel }) {
    const params = {
      since,
      until,
      business_hours: false,
      timezone_offset: getTimeOffset(),
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.get(`${this.url}/bot_analytics_sales_overview`, { params });
  }

  getCustomLiveChatSalesOverviewReports({ since, until, selectedLabel }) {
    const params = {
      since,
      until,
      business_hours: false,
      timezone_offset: getTimeOffset(),
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.get(`${this.url}/live_chat_analytics_sales_overview`, {
      params,
    });
  }

  getCustomBotAnalyticsSupportOverviewReports({ since, until, selectedLabel }) {
    const params = {
      since,
      until,
      business_hours: false,
      timezone_offset: getTimeOffset(),
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.get(`${this.url}/bot_analytics_support_overview`, { params });
  }

  getCustomLiveChatSupportOverviewReports({ since, until, selectedLabel }) {
    const params = {
      since,
      until,
      business_hours: false,
      timezone_offset: getTimeOffset(),
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.get(`${this.url}/live_chat_analytics_support_overview`, {
      params,
    });
  }

  getCurrency() {
    return axios.get(`${this.url}/shop_currency`);
  }

  getLiveChatCurrency() {
    return axios.get(`${this.url}/live_chat_shop_currency`);
  }

  downloadCustomAgentOverviewReports({
    since,
    until,
    businessHours,
    selectedLabel,
    selectedInbox,
    metricType,
    email,
  }) {
    const params = {
      since,
      until,
      business_hours: businessHours,
      metric_type: metricType,
      email,
    };

    if (selectedInbox) {
      params.inboxes = [selectedInbox.id];
    }

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.post(`${this.url}/download_agents_overview`, { ...params });
  }

  downloadCustomAgentWiseConversationStatesReports({
    since,
    until,
    businessHours,
    selectedLabel,
    selectedInbox,
    metricType,
    email,
  }) {
    const params = {
      since,
      until,
      business_hours: businessHours,
      metric_type: metricType,
      email,
    };

    if (selectedInbox) {
      params.inboxes = [selectedInbox.id];
    }

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.post(`${this.url}/download_agent_wise_conversation_states`, {
      ...params,
    });
  }

  downloadCustomBotAnalyticsOverviewReports({
    since,
    until,
    selectedLabel,
    email,
  }) {
    const params = {
      since,
      until,
      email,
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.post(`${this.url}/download_bot_analytics_overview`, {
      ...params,
    });
  }

  downloadCustomBotAnalyticsSalesOverviewReports({
    since,
    until,
    selectedLabel,
    email,
  }) {
    const params = {
      since,
      until,
      email,
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.post(`${this.url}/download_bot_analytics_sales_overview`, {
      ...params,
    });
  }

  downloadCustomLiveChatAnalyticsSalesOverviewReports({
    since,
    until,
    selectedLabel,
    email,
  }) {
    const params = {
      since,
      until,
      email,
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.post(
      `${this.url}/download_live_chat_analytics_sales_overview`,
      {
        ...params,
      }
    );
  }

  downloadCustomBotAnalyticsSupportOverviewReports({
    since,
    until,
    selectedLabel,
    email,
  }) {
    const params = {
      since,
      until,
      email,
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.post(`${this.url}/download_bot_analytics_support_overview`, {
      ...params,
    });
  }

  downloadCustomLiveChatAnalyticsSupportOverviewReports({
    since,
    until,
    selectedLabel,
    email,
  }) {
    const params = {
      since,
      until,
      email,
    };

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.post(
      `${this.url}/download_live_chat_analytics_support_overview`,
      {
        ...params,
      }
    );
  }

  getCustomAgentCallOverviewReports({
    since,
    until,
    businessHours,
    selectedLabel,
    selectedInbox,
  } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
      timezone_offset: getTimeOffset(),
    };

    if (selectedInbox) {
      params.inboxes = [selectedInbox.id];
    }

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.get(`${this.url}/agent_call_overview`, { params });
  }

  getCustomAgentInboundCallOverviewReports({
    since,
    until,
    businessHours,
    selectedLabel,
    selectedInbox,
  } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
      timezone_offset: getTimeOffset(),
    };

    if (selectedInbox) {
      params.inboxes = [selectedInbox.id];
    }

    if (selectedLabel) {
      params.labels = [selectedLabel.title];
    }

    return axios.get(`${this.url}/agent_inbound_call_overview`, { params });
  }

  getCallLogsReport({ startDate, endDate, email } = {}) {
    return axios.post(`/api/v1/call_logs/export_call_report`, {
      startDate,
      endDate,
      account_id: this.accountIdFromRoute,
      email,
    });
  }
}

export default new CustomReportsAPI();
