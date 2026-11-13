import { computed, toValue } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useTrack } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

const PROMPTS = {
  SUMMARIZE: {
    label: 'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.SUMMARIZE.CONTENT',
  },
  // "Suggest an answer" keeps the Assistant's reply path, so its answer matches the Assistant playground.
  SUGGEST: {
    label: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.SUGGEST.CONTENT',
    requestType: 'reply_suggestion',
  },
  RATE: {
    label: 'CAPTAIN.COPILOT.PROMPTS.RATE.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.RATE.CONTENT',
  },
  HIGH_PRIORITY: {
    label: 'CAPTAIN.COPILOT.PROMPTS.HIGH_PRIORITY.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.HIGH_PRIORITY.CONTENT',
  },
  LIST_CONTACTS: {
    label: 'CAPTAIN.COPILOT.PROMPTS.LIST_CONTACTS.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.LIST_CONTACTS.CONTENT',
  },
  CUSTOMER_HISTORY: {
    label: 'CAPTAIN.COPILOT.PROMPTS.CUSTOMER_HISTORY.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.CUSTOMER_HISTORY.CONTENT',
  },
  CAN_CLOSE: {
    label: 'CAPTAIN.COPILOT.PROMPTS.CAN_CLOSE.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.CAN_CLOSE.CONTENT',
  },
  FOLLOW_UPS: {
    label: 'CAPTAIN.COPILOT.PROMPTS.FOLLOW_UPS.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.FOLLOW_UPS.CONTENT',
  },
  UPSET_CUSTOMERS: {
    label: 'CAPTAIN.COPILOT.PROMPTS.UPSET_CUSTOMERS.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.UPSET_CUSTOMERS.CONTENT',
  },
  WAITING_ON_ME: {
    label: 'CAPTAIN.COPILOT.PROMPTS.WAITING_ON_ME.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.WAITING_ON_ME.CONTENT',
  },
  RECENT_CONVERSATIONS: {
    label: 'CAPTAIN.COPILOT.PROMPTS.RECENT_CONVERSATIONS.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.RECENT_CONVERSATIONS.CONTENT',
  },
  COMPARE_PERIODS: {
    label: 'CAPTAIN.COPILOT.PROMPTS.COMPARE_PERIODS.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.COMPARE_PERIODS.CONTENT',
  },
  SLOWEST_REPLIES: {
    label: 'CAPTAIN.COPILOT.PROMPTS.SLOWEST_REPLIES.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.SLOWEST_REPLIES.CONTENT',
  },
  LOW_RATINGS: {
    label: 'CAPTAIN.COPILOT.PROMPTS.LOW_RATINGS.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.LOW_RATINGS.CONTENT',
  },
  TEAM_WORKLOAD: {
    label: 'CAPTAIN.COPILOT.PROMPTS.TEAM_WORKLOAD.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.TEAM_WORKLOAD.CONTENT',
  },
  MONTHLY_VOLUME: {
    label: 'CAPTAIN.COPILOT.PROMPTS.MONTHLY_VOLUME.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.MONTHLY_VOLUME.CONTENT',
  },
  COMPARE_INBOXES: {
    label: 'CAPTAIN.COPILOT.PROMPTS.COMPARE_INBOXES.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.COMPARE_INBOXES.CONTENT',
  },
  LOW_RATINGS_BY_AGENT: {
    label: 'CAPTAIN.COPILOT.PROMPTS.LOW_RATINGS_BY_AGENT.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.LOW_RATINGS_BY_AGENT.CONTENT',
  },
  LABEL_RESOLVED: {
    label: 'CAPTAIN.COPILOT.PROMPTS.LABEL_RESOLVED.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.LABEL_RESOLVED.CONTENT',
  },
  CAPTAIN_HANDOFFS: {
    label: 'CAPTAIN.COPILOT.PROMPTS.CAPTAIN_HANDOFFS.LABEL',
    content: 'CAPTAIN.COPILOT.PROMPTS.CAPTAIN_HANDOFFS.CONTENT',
  },
};

// The older Copilot answers about the page the person is on.
const ROUTE_PROMPTS = {
  conversations: ['SUMMARIZE', 'SUGGEST', 'RATE'],
  dashboard: ['HIGH_PRIORITY', 'LIST_CONTACTS'],
};

// Workflows answers across many conversations, so its prompts follow the person's role. Agents can't read reports,
// so their prompts read conversations. Each prompt reads only conversations the person can open.
const ROLE_PROMPTS = {
  agent: [
    'CAN_CLOSE',
    'FOLLOW_UPS',
    'UPSET_CUSTOMERS',
    'WAITING_ON_ME',
    'RECENT_CONVERSATIONS',
  ],
  administrator: [
    'COMPARE_PERIODS',
    'SLOWEST_REPLIES',
    'LOW_RATINGS',
    'TEAM_WORKLOAD',
    'MONTHLY_VOLUME',
    'COMPARE_INBOXES',
    'LOW_RATINGS_BY_AGENT',
    'LABEL_RESOLVED',
    'CAPTAIN_HANDOFFS',
  ],
};

// Copilot reads the open conversation, so these join the role prompts while one is open.
const CONVERSATION_PROMPTS = ['CUSTOMER_HISTORY'];

const MAX_CONVERSATION_PROMPTS = 4;
const MAX_ROLE_PROMPTS = 3;

// Each prompt gets a random rank once per page load, so the pills stay put while someone reads them and the next
// visit shows another mix.
const promptRanks = {};
const rankOf = key => {
  if (!(key in promptRanks)) promptRanks[key] = Math.random();
  return promptRanks[key];
};
const byRank = keys => [...keys].sort((a, b) => rankOf(a) - rankOf(b));

export function useCopilotPrompts({ isWorkflowsEnabled, canSuggestReply }) {
  const { t } = useI18n();
  const route = useRoute();
  const currentRole = useMapGetter('getCurrentRole');
  const currentChat = useMapGetter('getSelectedChat');

  const workflowKeys = () => {
    const roleKeys = ROLE_PROMPTS[currentRole.value] || ROLE_PROMPTS.agent;
    if (!currentChat.value.id) {
      return byRank(roleKeys).slice(0, MAX_ROLE_PROMPTS);
    }

    // Summarizing the open conversation always comes first. The reply suggestion follows when the customer spoke last.
    const fixedKeys = toValue(canSuggestReply)
      ? ['SUMMARIZE', 'SUGGEST']
      : ['SUMMARIZE'];
    const randomKeys = byRank([...CONVERSATION_PROMPTS, ...roleKeys]);
    return [...fixedKeys, ...randomKeys].slice(0, MAX_CONVERSATION_PROMPTS);
  };

  const routeKeys = () => {
    const keys = route.path.includes('/conversations')
      ? ROUTE_PROMPTS.conversations
      : ROUTE_PROMPTS.dashboard;
    if (toValue(canSuggestReply)) return keys;

    return keys.filter(key => !PROMPTS[key].requestType);
  };

  const prompts = computed(() => {
    const keys = toValue(isWorkflowsEnabled) ? workflowKeys() : routeKeys();
    return keys.map(key => ({ key, label: t(PROMPTS[key].label) }));
  });

  // Records the click and returns what Copilot sends: the prompt text, with its request type when it has one.
  const selectPrompt = key => {
    useTrack(COPILOT_EVENTS.SEND_SUGGESTED, {
      prompt: key,
      role: currentRole.value,
    });
    const { content, requestType } = PROMPTS[key];
    const message = t(content);
    return requestType ? { message, requestType } : message;
  };

  return { prompts, selectPrompt };
}
