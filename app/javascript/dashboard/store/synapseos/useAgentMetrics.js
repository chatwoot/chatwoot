import { defineStore } from 'pinia';
import axios from 'axios';

// Slugs canônicos suportados pelo squadron (vide app/services/synapseos/agent_resolver.rb).
// Usado só para inicializar o estado por slug; a lista REAL exibida vem do backend.
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
  usage: null,
  usageLoading: false,
  usageError: null,
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
    activeSlugs: [],
    activeFetched: false,
    range: '30d',
    since: sinceFromRange('30d'),
    lastUpdatedAt: null,
  }),

  getters: {
    agentState: state => slug => state.agents[slug] || defaultAgentState(),
    hasActiveAgents: state => state.activeSlugs.length > 0,
  },

  actions: {
    setRange(rangeKey) {
      this.range = rangeKey;
      this.since = sinceFromRange(rangeKey);
      return this.fetchAll({ accountId: this._lastAccountId });
    },

    async fetchActiveAgents({ accountId }) {
      this._lastAccountId = accountId;
      try {
        const { data } = await axios.get(
          `/api/v1/accounts/${accountId}/synapseos/agent_metrics`
        );
        this.activeSlugs = Array.isArray(data?.slugs) ? data.slugs : [];
        if (Array.isArray(data?.agents)) {
          data.agents.forEach(a => {
            if (this.agents[a.slug]) this.agents[a.slug].displayName = a.display_name;
          });
        }
      } catch (_err) {
        this.activeSlugs = [];
      } finally {
        this.activeFetched = true;
      }
      return this.activeSlugs;
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

    async fetchAgentUsage({ accountId, slug }) {
      const agent = this.agents[slug];
      if (!agent) return;
      agent.usageLoading = true;
      agent.usageError = null;
      try {
        const { data } = await axios.get(
          `/api/v1/accounts/${accountId}/synapseos/agent_metrics/${slug}/usage`
        );
        agent.usage = data;
      } catch (err) {
        agent.usageError = err?.response?.data?.error || err.message || 'unknown_error';
      } finally {
        agent.usageLoading = false;
      }
    },

    async fetchAll({ accountId }) {
      this._lastAccountId = accountId;
      const slugs = await this.fetchActiveAgents({ accountId });
      if (slugs.length > 0) {
        await Promise.all([
          ...slugs.map(slug => this.fetchAgent({ accountId, slug })),
          ...slugs.map(slug => this.fetchAgentUsage({ accountId, slug })),
        ]);
      }
      this.lastUpdatedAt = new Date().toISOString();
    },
  },
});
