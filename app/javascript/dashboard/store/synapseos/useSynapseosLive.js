// CUSTOMIZAÇÃO_SYNAPSEOS: store do dashboard Live Agents (6 bots + conversas quentes).
// Consome REST `/synapseos/agent_metrics/live` + ActionCable `Synapseos::LiveChannel`.
import { defineStore } from 'pinia';
import { createConsumer } from '@rails/actioncable';
import axios from 'axios';

const buildConsumer = () => {
  const { websocketURL = '' } = window.chatwootConfig || {};
  const url = websocketURL ? `${websocketURL}/cable` : undefined;
  return createConsumer(url);
};

export const useSynapseosLiveStore = defineStore('synapseosLive', {
  state: () => ({
    agents: [],
    hotConversations: [],
    isLoading: false,
    error: null,
    isConnected: false,
    // runtime-only refs (not reactive state we depend on)
    _consumer: null,
    _subscription: null,
    _accountId: null,
  }),

  getters: {
    agentBySlug: state => slug => state.agents.find(a => a.slug === slug),
  },

  actions: {
    async fetchLive(accountId) {
      this.isLoading = true;
      this.error = null;
      this._accountId = accountId;
      try {
        const { data } = await axios.get(
          `/api/v1/accounts/${accountId}/synapseos/agent_metrics/live`
        );
        this.agents = data.agents || [];
        this.hotConversations = data.hot_conversations || [];
      } catch (err) {
        this.error = err?.response?.data?.error || err.message;
      } finally {
        this.isLoading = false;
      }
    },

    subscribe({ accountId, pubsubToken }) {
      if (this._subscription) return;
      this._accountId = accountId;
      this._consumer = buildConsumer();
      this._subscription = this._consumer.subscriptions.create(
        {
          channel: 'Synapseos::LiveChannel',
          account_id: accountId,
          pubsub_token: pubsubToken,
        },
        {
          connected: () => {
            this.isConnected = true;
          },
          disconnected: () => {
            this.isConnected = false;
          },
          received: payload => this.handleBroadcast(payload),
        }
      );
    },

    unsubscribe() {
      if (this._subscription) {
        this._subscription.unsubscribe();
        this._subscription = null;
      }
      if (this._consumer) {
        this._consumer.disconnect();
        this._consumer = null;
      }
      this.isConnected = false;
    },

    handleBroadcast(payload) {
      if (!payload || !payload.type) return;
      switch (payload.type) {
        case 'agent_activity':
          this.applyAgentActivity(payload);
          break;
        case 'label_event':
          this.applyLabelEvent(payload);
          break;
        case 'deal_stage_changed':
          // No UI binding yet. Log for debuggability.
          // eslint-disable-next-line no-console
          console.debug('[SynapseosLive] deal_stage_changed', payload);
          break;
        default:
          break;
      }
    },

    applyAgentActivity({ agent_slug: slug, action, at }) {
      const agent = this.agents.find(a => a.slug === slug);
      if (!agent) return;
      agent.last_action = action;
      agent.last_action_at = at;
      agent.status = 'online';
    },

    applyLabelEvent({ conversation_id: id, label, at }) {
      const conv = this.hotConversations.find(c => c.id === id);
      if (!conv) return;
      conv.status_label = label;
      conv.time_in_stage_seconds = 0;
      conv.last_activity_at = at;
    },
  },
});
