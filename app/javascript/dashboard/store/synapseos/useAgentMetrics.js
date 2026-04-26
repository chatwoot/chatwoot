import { defineStore } from 'pinia';
import axios from 'axios';

export const AGENT_SLUGS = ['alice', 'iza', 'otto', 'luis', 'fernanda', 'angela', 'vitor'];

export const RANGE_OPTIONS = [
  { key: '24h', labelKey: 'SYNAPSEOS.METRICS.RANGES.24H', hours: 24 },
  { key: '7d', labelKey: 'SYNAPSEOS.METRICS.RANGES.7D', hours: 24 * 7 },
  { key: '30d', labelKey: 'SYNAPSEOS.METRICS.RANGES.30D', hours: 24 * 30 },
  { key: '90d', labelKey: 'SYNAPSEOS.METRICS.RANGES.90D', hours: 24 * 90 },
];

const defaultAgentState = () => ({
  isLoading: false,
  error: null,
  kpis: {},
  since: null,
  displayName: null,
});

const buildInitialAgents = () =>
  AGENT_SLUGS.reduce((acc, slug) => {
    acc[slug] = defaultAgentState();
    return acc;
  }, {});

const sinceFromRange = rangeKey => {
  const option = RANGE_OPTIONS.find(r => r.key === rangeKey) || RANGE_OPTIONS[2];
  const ms = option.hours * 60 * 60 * 1000;
  return new Date(Date.now() - ms).toISOString();
};

export const useAgentMetricsStore = defineStore('synapseosAgentMetrics', {
  state: () => ({
    agents: buildInitialAgents(),
    range: '30d',
    since: sinceFromRange('30d'),
    lastUpdatedAt: null,
  }),

  getters: {
    agentState: state => slug => state.agents[slug] || defaultAgentState(),
  },

  actions: {
    setRange(rangeKey) {
      this.range = rangeKey;
      this.since = sinceFromRange(rangeKey);
      return this.fetchAll({ accountId: this._lastAccountId });
    },

    async fetchAgent({ accountId, slug }) {
      const agent = this.agents[slug];
      if (!agent) return;
      agent.isLoading = true;
      agent.error = null;
      this._lastAccountId = accountId;
      try {
        const { data } = await axios.get(
          `/api/v1/accounts/${accountId}/synapseos/agent_metrics/${slug}`,
          { params: { since: this.since } }
        );
        agent.kpis = data.kpis || {};
        agent.since = data.since;
        agent.displayName = data.display_name;
      } catch (err) {
        agent.error = err?.response?.data?.error || err.message || 'unknown_error';
      } finally {
        agent.isLoading = false;
      }
    },

    async fetchAll({ accountId }) {
      this._lastAccountId = accountId;
      await Promise.all(
        AGENT_SLUGS.map(slug => this.fetchAgent({ accountId, slug }))
      );
      this.lastUpdatedAt = new Date().toISOString();
    },
  },
});
