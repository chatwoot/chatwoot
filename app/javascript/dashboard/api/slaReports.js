/* global axios */
import ApiClient from './ApiClient';

class SLAReportsAPI extends ApiClient {
  constructor() {
    super('applied_slas', { accountScoped: true });
  }

  get({
    from,
    to,
    assigned_agent_id,
    inbox_id,
    team_id,
    sla_policy_id,
    label_list,
    page,
  } = {}) {
    return axios.get(this.url, {
      params: {
        since: from,
        until: to,
        assigned_agent_id,
        inbox_id,
        team_id,
        sla_policy_id,
        label_list,
        page,
      },
    });
  }

  download({
    from,
    to,
    assigned_agent_id,
    inbox_id,
    team_id,
    sla_policy_id,
    label_list,
  } = {}) {
    return axios.get(`${this.url}/download`, {
      params: {
        since: from,
        until: to,
        assigned_agent_id,
        inbox_id,
        team_id,
        label_list,
        sla_policy_id,
      },
    });
  }

  getMetrics({
    from,
    to,
    assigned_agent_id,
    inbox_id,
    team_id,
    label_list,
    sla_policy_id,
  } = {}) {
    return axios.get(`${this.url}/metrics`, {
      params: {
        since: from,
        until: to,
        assigned_agent_id,
        inbox_id,
        label_list,
        team_id,
        sla_policy_id,
      },
    });
  }
}

export default new SLAReportsAPI();
