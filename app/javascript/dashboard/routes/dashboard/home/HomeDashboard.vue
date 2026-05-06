<script setup>
import { computed, ref, onMounted, onBeforeUnmount, watch } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { formatTime, evaluateSLAStatus } from '@chatwoot/utils';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useUISettings } from 'dashboard/composables/useUISettings';
import ConversationApi from 'dashboard/api/inbox/conversation';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import InboxName from 'dashboard/components-next/Conversation/InboxName.vue';
import CardPriorityIcon from 'dashboard/components-next/Conversation/ConversationCard/CardPriorityIcon.vue';
import MessagePreview from 'dashboard/components-next/Conversation/ConversationCard/MessagePreview.vue';

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();
const { accountScopedRoute } = useAccount();
const { uiSettings } = useUISettings();

const currentUser = computed(() => store.getters.getCurrentUser);
const currentAccountId = computed(() => store.getters.getCurrentAccountId);
const currentRole = computed(() => {
  const accounts = currentUser.value?.accounts || [];
  const acc = accounts.find(a => a.id === currentAccountId.value);
  return acc?.role || 'agent';
});
const isAdmin = computed(() => currentRole.value === 'administrator');

const view = computed(() =>
  route.name === 'home_dashboard_admin' ? 'admin' : 'agent'
);

const agentRoute = computed(() => accountScopedRoute('home_dashboard'));
const adminRoute = computed(() => accountScopedRoute('home_dashboard_admin'));

const firstName = computed(() => {
  const name = currentUser.value?.name || '';
  return (
    name.split(' ')[0] ||
    name ||
    t('HOME_DASHBOARD_PAGE.GREETING.FALLBACK_NAME')
  );
});

const greeting = computed(() => {
  const hour = new Date().getHours();
  if (hour >= 5 && hour < 12) {
    return t('HOME_DASHBOARD_PAGE.GREETING.MORNING');
  }
  if (hour >= 12 && hour < 17) {
    return t('HOME_DASHBOARD_PAGE.GREETING.AFTERNOON');
  }
  if (hour >= 17 && hour < 22) {
    return t('HOME_DASHBOARD_PAGE.GREETING.EVENING');
  }
  return t('HOME_DASHBOARD_PAGE.GREETING.LATE');
});

// ── Data sources ──────────────────────────────────────────────
const unreadNotifications = useMapGetter('notifications/getUnreadCount');
const conversationStats = useMapGetter('conversationStats/getStats');
const accountSummary = useMapGetter('getAccountSummary');
const agents = useMapGetter('agents/getVerifiedAgents');
const agentConversationMetric = useMapGetter('getAgentConversationMetric');
const inboxByIdGetter = useMapGetter('inboxes/getInboxById');
const captainAssistants = useMapGetter('captainAssistants/getRecords');

const activeAssistant = computed(() => {
  const preferredId = uiSettings.value.preferred_captain_assistant_id;
  if (preferredId) {
    const found = captainAssistants.value.find(a => a.id === preferredId);
    if (found) return found;
  }
  return captainAssistants.value[0];
});

const todayRange = () => {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);
  return {
    from: Math.floor(startOfDay.getTime() / 1000),
    to: Math.floor(endOfDay.getTime() / 1000),
  };
};

const mineConversations = ref([]);
const isLoadingMine = ref(false);
const mineUnattendedCount = ref(0);
const agentSortValue = ref('waiting_since_asc');

const fetchMineUnattendedCount = async () => {
  try {
    const { data } = await ConversationApi.meta({
      assigneeType: 'me',
      status: 'open',
      conversationType: 'unattended',
    });
    mineUnattendedCount.value = data?.meta?.mine_count ?? 0;
  } catch {
    mineUnattendedCount.value = 0;
  }
};

const fetchMineConversations = async () => {
  isLoadingMine.value = true;
  try {
    const { data } = await ConversationApi.get({
      assigneeType: 'me',
      status: 'open',
      page: 1,
      sortBy: agentSortValue.value,
    });
    mineConversations.value = data?.data?.payload?.slice(0, 10) || [];
  } catch {
    mineConversations.value = [];
  } finally {
    isLoadingMine.value = false;
  }
};

const fetchData = () => {
  store.dispatch('notifications/unReadCount');
  store.dispatch('agents/get');
  store.dispatch('captainAssistants/get');
  store.dispatch('copilotThreads/get');
  store.dispatch('conversationStats/get', { status: 'open' });
  const range = todayRange();
  store.dispatch('fetchAccountSummary', {
    from: range.from,
    to: range.to,
    groupBy: 'day',
    businessHours: false,
  });
  if (view.value === 'admin') {
    store.dispatch('fetchAgentConversationMetric');
  } else {
    fetchMineConversations();
    fetchMineUnattendedCount();
  }
};

onMounted(fetchData);

watch(view, fetchData);

// ── KPI values (computed from store) ──────────────────────────
const openConversationsValue = computed(() => {
  if (view.value === 'admin') {
    return String(conversationStats.value?.allCount ?? 0);
  }
  return String(conversationStats.value?.mineCount ?? 0);
});

const firstResponseValue = computed(() => {
  const seconds = accountSummary.value?.avg_first_response_time || 0;
  return seconds ? formatTime(seconds) : '—';
});

const resolvedTodayValue = computed(() => {
  return String(accountSummary.value?.resolutions_count ?? 0);
});

const notificationsValue = computed(() =>
  String(unreadNotifications.value ?? 0)
);

const adminKpis = computed(() => [
  {
    label: t('HOME_DASHBOARD_PAGE.KPI.OPEN_CONVERSATIONS'),
    icon: 'i-lucide-message-circle',
    value: openConversationsValue.value,
    unit: '',
    to: accountScopedRoute('home'),
  },
  {
    label: t('HOME_DASHBOARD_PAGE.KPI.AVG_FIRST_RESPONSE'),
    icon: 'i-lucide-clock',
    value: firstResponseValue.value,
    unit: '',
  },
  {
    label: t('HOME_DASHBOARD_PAGE.KPI.RESOLVED_TODAY'),
    icon: 'i-lucide-check',
    value: resolvedTodayValue.value,
    unit: '',
  },
  {
    label: t('HOME_DASHBOARD_PAGE.KPI.TEAM_CSAT_TODAY'),
    icon: 'i-lucide-heart',
    value: '—',
    unit: '',
  },
]);
const agentKpis = computed(() => [
  {
    label: t('HOME_DASHBOARD_PAGE.KPI.OPEN_CONVERSATIONS'),
    icon: 'i-lucide-message-circle',
    value: openConversationsValue.value,
    unit: '',
    to: accountScopedRoute('home'),
  },
  {
    label: t('HOME_DASHBOARD_PAGE.KPI.FIRST_RESPONSE'),
    icon: 'i-lucide-clock',
    value: firstResponseValue.value,
    unit: '',
  },
  {
    label: t('HOME_DASHBOARD_PAGE.KPI.RESOLVED_TODAY'),
    icon: 'i-lucide-check',
    value: resolvedTodayValue.value,
    unit: '',
  },
  {
    label: t('HOME_DASHBOARD_PAGE.KPI.NOTIFICATIONS'),
    icon: 'i-lucide-bell',
    value: notificationsValue.value,
    unit: '',
    to: accountScopedRoute('inbox_view'),
  },
]);
const kpis = computed(() =>
  view.value === 'admin' ? adminKpis.value : agentKpis.value
);

// ── Greeting summary numbers ──────────────────────────────────
const teamOpenCount = computed(() => conversationStats.value?.allCount ?? 0);
const mineOpenCount = computed(() => conversationStats.value?.mineCount ?? 0);
const onlineAgentsCount = computed(
  () => agents.value.filter(a => a.availability_status === 'online').length
);
const mineNearSlaCount = computed(
  () =>
    mineConversations.value.filter(chat => {
      const status = evaluateSLAStatus({
        appliedSla: chat.applied_sla || {},
        chat,
      });
      return !!status?.threshold;
    }).length
);

// ── AI input + suggestions ────────────────────────────────────
const aiPlaceholderKeysAdmin = [
  'HOME_DASHBOARD_PAGE.AI_PLACEHOLDERS_ADMIN.DEFAULT',
  'HOME_DASHBOARD_PAGE.AI_PLACEHOLDERS_ADMIN.SUMMARIZE',
  'HOME_DASHBOARD_PAGE.AI_PLACEHOLDERS_ADMIN.DRAFT_REPLY',
  'HOME_DASHBOARD_PAGE.AI_PLACEHOLDERS_ADMIN.WHY_CSAT',
  'HOME_DASHBOARD_PAGE.AI_PLACEHOLDERS_ADMIN.FIND_TICKETS',
];
const aiPlaceholderKeysAgent = [
  'HOME_DASHBOARD_PAGE.AI_PLACEHOLDERS_AGENT.DEFAULT',
  'HOME_DASHBOARD_PAGE.AI_PLACEHOLDERS_AGENT.SUMMARIZE',
  'HOME_DASHBOARD_PAGE.AI_PLACEHOLDERS_AGENT.DRAFT_REPLY',
  'HOME_DASHBOARD_PAGE.AI_PLACEHOLDERS_AGENT.WHY_CSAT',
  'HOME_DASHBOARD_PAGE.AI_PLACEHOLDERS_AGENT.FIND_TICKETS',
];
const aiPlaceholderKeys = computed(() =>
  view.value === 'admin' ? aiPlaceholderKeysAdmin : aiPlaceholderKeysAgent
);
const placeholderIndex = ref(0);
const aiInput = ref('');
const aiInputEl = ref(null);
const currentPlaceholder = computed(() =>
  t(aiPlaceholderKeys.value[placeholderIndex.value])
);

let placeholderTimer = null;
onMounted(() => {
  placeholderTimer = setInterval(() => {
    if (document.activeElement === aiInputEl.value || aiInput.value) return;
    placeholderIndex.value =
      (placeholderIndex.value + 1) % aiPlaceholderKeys.value.length;
  }, 3500);
});
onBeforeUnmount(() => {
  if (placeholderTimer) clearInterval(placeholderTimer);
});

// `suggestions` defined further below — depends on `team` computed.

const onSuggestion = chip => {
  aiInput.value = chip;
  aiInputEl.value?.focus();
};

const isSubmitting = ref(false);
const canSubmit = computed(
  () => !!aiInput.value.trim() && !!activeAssistant.value && !isSubmitting.value
);

const submitToCopilot = async () => {
  const message = aiInput.value.trim();
  if (!message || !activeAssistant.value || isSubmitting.value) return;
  isSubmitting.value = true;
  try {
    const response = await store.dispatch('copilotThreads/create', {
      assistant_id: activeAssistant.value.id,
      message,
    });
    aiInput.value = '';
    router.push(
      accountScopedRoute('home_copilot_thread', { threadId: response.id })
    );
  } catch (error) {
    useAlert(error.message);
  } finally {
    isSubmitting.value = false;
  }
};

// ── Sort ──────────────────────────────────────────────────────
const adminSortKeys = [
  'HOME_DASHBOARD_PAGE.SORT_OPTIONS_ADMIN.CAPACITY',
  'HOME_DASHBOARD_PAGE.SORT_OPTIONS_ADMIN.FIRST_RESPONSE',
  'HOME_DASHBOARD_PAGE.SORT_OPTIONS_ADMIN.CSAT_TODAY',
  'HOME_DASHBOARD_PAGE.SORT_OPTIONS_ADMIN.RESOLVED_TODAY',
];
// Agent sort uses the same options the conversation list offers,
// so keys are the API sort_by values and labels reuse CHAT_LIST.SORT_ORDER_ITEMS.
const agentSortValues = [
  'waiting_since_asc',
  'waiting_since_desc',
  'priority_desc',
  'priority_asc',
  'priority_desc_created_at_asc',
  'last_activity_at_desc',
  'last_activity_at_asc',
  'created_at_desc',
  'created_at_asc',
];
const sortByKey = ref(adminSortKeys[0]);
const sortOpen = ref(false);
const sortOptions = computed(() => {
  if (view.value === 'admin') {
    return adminSortKeys.map(key => ({ key, label: t(key) }));
  }
  return agentSortValues.map(value => ({
    key: value,
    label: t(`CHAT_LIST.SORT_ORDER_ITEMS.${value}.TEXT`),
  }));
});
const sortByLabel = computed(() => {
  if (view.value === 'admin') return t(sortByKey.value);
  return t(`CHAT_LIST.SORT_ORDER_ITEMS.${agentSortValue.value}.TEXT`);
});

const onSortSelect = key => {
  if (view.value === 'admin') {
    sortByKey.value = key;
  } else {
    agentSortValue.value = key;
    fetchMineConversations();
  }
  sortOpen.value = false;
};

watch(view, () => {
  sortByKey.value = adminSortKeys[0];
  placeholderIndex.value = 0;
});

// ── Team workload (admin) ─────────────────────────────────────
const AGENT_AVATAR_COLORS = [
  '#5EA9FF',
  '#12A594',
  '#5B5BD6',
  '#E5734A',
  '#A87819',
  '#6E5BCF',
  '#C75A45',
];

const initialsFor = name =>
  (name || '?')
    .split(/\s+/)
    .map(w => w[0])
    .filter(Boolean)
    .slice(0, 2)
    .join('')
    .toUpperCase();

const colorFor = id => AGENT_AVATAR_COLORS[id % AGENT_AVATAR_COLORS.length];

const metricFor = id =>
  agentConversationMetric.value.find(m => m.assignee_id === Number(id)) || {};

const team = computed(() => {
  const myId = currentUser.value?.id;
  return agents.value
    .map(agent => {
      const metric = metricFor(agent.id);
      const open = metric.open || 0;
      const cap = 20;
      const capacity = Math.min(100, Math.round((open / cap) * 100));
      let capacityTone = 'ok';
      if (agent.availability_status === 'offline') capacityTone = 'off';
      else if (capacity >= 85) capacityTone = 'danger';
      else if (capacity >= 65) capacityTone = 'warn';
      const statusLabels = {
        online: 'Online',
        busy: 'Busy',
        offline: 'Offline',
      };
      return {
        id: agent.id,
        initials: initialsFor(agent.available_name || agent.name),
        bg: colorFor(agent.id),
        name: agent.available_name || agent.name,
        sub: statusLabels[agent.availability_status] || 'Offline',
        status: agent.availability_status,
        capacity,
        capacityTone,
        primary: `${metric.unattended || 0} / ${open}`,
        frt: '—',
        csat: '—',
        csatTone: 'neutral',
        isYou: agent.id === myId,
      };
    })
    .sort((a, b) => b.capacity - a.capacity);
});

const overloadedAgent = computed(
  () => team.value.find(a => a.capacityTone === 'danger') || null
);

const suggestions = computed(() => {
  const list = [];
  if (view.value === 'admin') {
    if (teamOpenCount.value > 50) {
      list.push(
        t('HOME_DASHBOARD_PAGE.SUGGESTIONS_ADMIN.HIGH_VOLUME', {
          count: teamOpenCount.value,
        })
      );
    }
    if (overloadedAgent.value) {
      list.push(t('HOME_DASHBOARD_PAGE.SUGGESTIONS_ADMIN.OVERLOADED'));
      list.push(
        t('HOME_DASHBOARD_PAGE.SUGGESTIONS_ADMIN.COACH_AGENT', {
          name: overloadedAgent.value.name,
        })
      );
    } else {
      list.push(t('HOME_DASHBOARD_PAGE.SUGGESTIONS_ADMIN.TEAM_PERFORMANCE'));
    }
    list.push(t('HOME_DASHBOARD_PAGE.SUGGESTIONS_ADMIN.CSAT_OUTLIERS'));
    list.push(t('HOME_DASHBOARD_PAGE.SUGGESTIONS_ADMIN.FIND_PATTERNS'));
  } else {
    if (mineOpenCount.value === 0) {
      list.push(t('HOME_DASHBOARD_PAGE.SUGGESTIONS_AGENT.SLOW_DAY'));
      list.push(t('HOME_DASHBOARD_PAGE.SUGGESTIONS_AGENT.CATCH_UP'));
      return list;
    }
    list.push(t('HOME_DASHBOARD_PAGE.SUGGESTIONS_AGENT.SUMMARIZE_QUEUE'));
    if (mineNearSlaCount.value > 0) {
      list.push(t('HOME_DASHBOARD_PAGE.SUGGESTIONS_AGENT.NEAR_SLA'));
    } else {
      list.push(t('HOME_DASHBOARD_PAGE.SUGGESTIONS_AGENT.URGENT'));
    }
    if (mineUnattendedCount.value > 0) {
      list.push(
        t('HOME_DASHBOARD_PAGE.SUGGESTIONS_AGENT.TRIAGE_UNATTENDED', {
          count: mineUnattendedCount.value,
        })
      );
    }
    const firstConv = mineConversations.value[0];
    const firstContactName = firstConv?.meta?.sender?.name;
    if (firstContactName) {
      list.push(
        t('HOME_DASHBOARD_PAGE.SUGGESTIONS_AGENT.SUMMARIZE_CONVERSATION', {
          name: firstContactName,
        })
      );
    }
  }
  return list.slice(0, 4);
});

// ── Recent copilot threads ────────────────────────────────────
const copilotThreads = useMapGetter('copilotThreads/getRecords');
const recentThreads = computed(() => copilotThreads.value.slice(0, 3));

const goToThread = id =>
  router.push(accountScopedRoute('home_copilot_thread', { threadId: id }));

// ── Top mine conversations (agent) ────────────────────────────
const conversations = computed(() =>
  mineConversations.value.map(conv => {
    const lastMsg = conv.messages?.length
      ? getLastMessage(conv)
      : conv.last_non_activity_message;
    const contactName = conv.meta?.sender?.name || 'Unknown';
    const inbox = inboxByIdGetter.value(conv.inbox_id) || {};
    return {
      id: `#${conv.id}`,
      conversationId: conv.id,
      initials: initialsFor(contactName),
      bg: colorFor(conv.meta?.sender?.id || conv.id),
      name: contactName,
      lastMessage: lastMsg,
      inbox,
      priority: conv.priority || '',
    };
  })
);

// ── Attention items (admin) ───────────────────────────────────
// Static placeholder cards until Captain insights API exists.
const attention = [
  {
    tone: 'iris',
    icon: 'i-lucide-book-open',
    title: 'SAML SSO requests piling up',
    body: '5 customers asked about SAML SSO setup this week. No KB article exists — drafting one would deflect ~6 conversations a week.',
    cta: 'Draft article',
  },
  {
    tone: 'rose',
    icon: 'i-lucide-star',
    title: '2 ratings of 1 star this week',
    body: "Both came from Sam L.'s queue — refund miscommunications. Worth reviewing for coaching at next 1:1.",
    cta: 'Review conversations',
  },
  {
    tone: 'amber',
    icon: 'i-lucide-activity',
    title: 'Refund queries up 40% this week',
    body: 'Most reference the new annual auto-renewal flow. Captain suggests a one-time email to recent renewals explaining the change.',
    cta: 'See pattern',
  },
];
</script>

<template>
  <section
    class="flex w-full h-full overflow-y-auto bg-n-surface-1 text-n-slate-12"
  >
    <div class="w-full max-w-[1100px] mx-auto px-9 pt-14 pb-16">
      <div class="flex items-start justify-between gap-6 mb-7">
        <header class="flex-1 min-w-0">
          <h1
            class="m-0 text-[44px] leading-[1.05] tracking-[-0.012em] font-normal font-serif"
          >
            {{ $t('HOME_DASHBOARD_PAGE.GREETING.GREETING_LINE', { greeting })
            }}<em class="italic text-n-brand">{{
              $t('HOME_DASHBOARD_PAGE.GREETING.NAME_LINE', { name: firstName })
            }}</em>
          </h1>
          <p
            v-if="view === 'admin'"
            class="mt-2.5 text-n-slate-11 text-[14.5px]"
          >
            {{ $t('HOME_DASHBOARD_PAGE.TEAM_SUMMARY.PREFIX')
            }}<b class="text-n-slate-12 font-medium">{{
              $t('HOME_DASHBOARD_PAGE.TEAM_SUMMARY.OPEN_CONVERSATIONS', {
                count: teamOpenCount,
              })
            }}</b
            >{{ $t('HOME_DASHBOARD_PAGE.TEAM_SUMMARY.AND')
            }}<b class="text-n-slate-12 font-medium">{{
              $t('HOME_DASHBOARD_PAGE.TEAM_SUMMARY.AGENTS_ONLINE', {
                count: onlineAgentsCount,
              })
            }}</b
            >{{ $t('HOME_DASHBOARD_PAGE.TEAM_SUMMARY.PERIOD') }}
          </p>
          <p v-else class="mt-2.5 text-n-slate-11 text-[14.5px]">
            {{ $t('HOME_DASHBOARD_PAGE.AGENT_SUMMARY.PREFIX')
            }}<b class="text-n-slate-12 font-medium">{{
              $t('HOME_DASHBOARD_PAGE.AGENT_SUMMARY.OPEN_CONVERSATIONS', {
                count: mineOpenCount,
              })
            }}</b
            >{{ $t('HOME_DASHBOARD_PAGE.AGENT_SUMMARY.MID')
            }}<b class="text-n-slate-12 font-medium">{{
              $t('HOME_DASHBOARD_PAGE.AGENT_SUMMARY.UNATTENDED', {
                count: mineUnattendedCount,
              })
            }}</b
            >{{ $t('HOME_DASHBOARD_PAGE.AGENT_SUMMARY.AND')
            }}<span class="text-n-amber-11 font-medium">{{
              $t('HOME_DASHBOARD_PAGE.AGENT_SUMMARY.NEARING_SLA', {
                count: mineNearSlaCount,
              })
            }}</span
            >{{ $t('HOME_DASHBOARD_PAGE.AGENT_SUMMARY.PERIOD') }}
          </p>
        </header>
        <div
          v-if="isAdmin"
          class="inline-flex bg-n-solid-1 border border-n-strong rounded-lg p-[3px] flex-shrink-0"
        >
          <router-link
            :to="agentRoute"
            class="px-3 py-1 rounded-md text-[12.5px] font-medium transition-colors"
            :class="
              view === 'agent'
                ? 'bg-n-alpha-2 text-n-slate-12'
                : 'text-n-slate-10 hover:text-n-slate-11'
            "
          >
            {{ $t('HOME_DASHBOARD_PAGE.ROLE_SWITCH.AGENT') }}
          </router-link>
          <router-link
            :to="adminRoute"
            class="px-3 py-1 rounded-md text-[12.5px] font-medium transition-colors"
            :class="
              view === 'admin'
                ? 'bg-n-alpha-2 text-n-slate-12'
                : 'text-n-slate-10 hover:text-n-slate-11'
            "
          >
            {{ $t('HOME_DASHBOARD_PAGE.ROLE_SWITCH.ADMIN') }}
          </router-link>
        </div>
      </div>

      <section
        class="mb-9 grid grid-cols-2 lg:grid-cols-4 rounded-xl border border-n-strong bg-n-solid-1 overflow-hidden"
      >
        <div
          v-for="(kpi, idx) in kpis"
          :key="kpi.label"
          class="px-5 pt-[18px] pb-4 border-n-strong lg:border-r"
          :class="[
            idx % 2 === 0 ? 'border-r' : '',
            idx === kpis.length - 1 ? 'lg:border-r-0' : '',
            idx < 2 ? 'border-b lg:border-b-0' : '',
          ]"
        >
          <div
            class="flex items-center justify-between mb-3 text-xs font-medium text-n-slate-11 tracking-[0.005em]"
          >
            <span>{{ kpi.label }}</span>
            <span class="size-3.5 text-n-slate-10" :class="[kpi.icon]" />
          </div>
          <div
            class="flex items-baseline gap-1 text-[28px] font-semibold leading-none tracking-[-0.022em] text-n-slate-12 tabular-nums"
          >
            <span>{{ kpi.value }}</span>
            <span v-if="kpi.unit" class="text-xs font-medium text-n-slate-10">
              {{ kpi.unit }}
            </span>
          </div>
          <router-link
            v-if="kpi.to"
            :to="kpi.to"
            class="mt-2.5 inline-flex items-center gap-1 text-xs font-medium text-n-brand hover:gap-1.5 transition-[gap]"
          >
            {{ $t('HOME_DASHBOARD_PAGE.KPI.SEE_ALL') }}
            <span class="i-lucide-chevron-right size-3" />
          </router-link>
          <button
            v-else
            class="mt-2.5 inline-flex items-center gap-1 text-xs font-medium text-n-brand hover:gap-1.5 transition-[gap] cursor-pointer bg-transparent border-0 p-0"
          >
            {{ $t('HOME_DASHBOARD_PAGE.KPI.SEE_ALL') }}
            <span class="i-lucide-chevron-right size-3" />
          </button>
        </div>
      </section>

      <div
        class="mb-9 relative rounded-2xl p-px overflow-hidden bg-gradient-to-br from-n-violet-9/40 via-n-violet-9/10 to-transparent"
      >
        <form
          class="rounded-[15px] bg-n-solid-1 px-5 pt-4 pb-3 transition-[box-shadow] focus-within:shadow-[0_0_0_3px_rgba(123,97,255,0.18)]"
          @submit.prevent="submitToCopilot"
        >
          <div class="flex items-center gap-3">
            <span class="relative flex-shrink-0">
              <span
                class="absolute inset-0 rounded-full bg-n-violet-9/15 blur-md"
              />
              <span
                class="relative i-ph-sparkle-fill size-[22px] text-n-violet-9"
              />
            </span>
            <input
              ref="aiInputEl"
              v-model="aiInput"
              :placeholder="currentPlaceholder"
              autocomplete="off"
              class="flex-1 min-w-0 border-0 bg-transparent text-n-slate-12 text-[15px] py-1 outline-none placeholder:text-n-slate-10"
            />
            <button
              v-if="aiInput.trim()"
              type="submit"
              :disabled="!canSubmit"
              class="inline-flex items-center gap-1.5 h-8 px-3 rounded-lg bg-n-violet-9 text-white text-[13px] font-medium hover:enabled:bg-n-violet-10 disabled:opacity-60 disabled:cursor-not-allowed transition-colors border-0 cursor-pointer shadow-[0_2px_8px_rgba(123,97,255,0.32)]"
            >
              {{ $t('HOME_DASHBOARD_PAGE.COPILOT_THREAD.SEND') }}
              <span class="i-lucide-arrow-up size-3.5" />
            </button>
          </div>
          <div class="flex flex-wrap gap-1.5 mt-3 pl-9">
            <button
              v-for="chip in suggestions"
              :key="chip"
              type="button"
              class="inline-flex items-center px-2.5 py-1 rounded-full border border-n-strong text-xs text-n-slate-11 hover:text-n-violet-11 hover:border-n-violet-9/40 hover:bg-n-violet-9/10 transition-colors cursor-pointer bg-transparent"
              @click="onSuggestion(chip)"
            >
              {{ chip }}
            </button>
          </div>
          <div
            v-if="recentThreads.length"
            class="mt-3 pt-3 pl-9 border-t border-n-strong/60"
          >
            <div
              class="text-[10.5px] uppercase tracking-[0.08em] font-medium text-n-slate-10 mb-2"
            >
              {{ $t('HOME_DASHBOARD_PAGE.RECENT_THREADS.TITLE') }}
            </div>
            <div class="flex flex-col gap-0.5">
              <button
                v-for="thread in recentThreads"
                :key="thread.id"
                type="button"
                class="flex items-center gap-2 w-full text-left px-2 py-1.5 -mx-2 rounded-md text-[13px] text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 transition-colors cursor-pointer bg-transparent border-0"
                @click="goToThread(thread.id)"
              >
                <span
                  class="i-lucide-message-square-text size-3.5 text-n-slate-10 flex-shrink-0"
                />
                <span class="truncate flex-1 min-w-0">
                  {{ thread.title || `Thread #${thread.id}` }}
                </span>
                <span
                  class="i-lucide-chevron-right size-3 text-n-slate-10 flex-shrink-0"
                />
              </button>
            </div>
          </div>
        </form>
      </div>

      <div class="flex items-baseline justify-between mb-3.5">
        <h2
          class="m-0 inline-flex items-center gap-2 text-sm font-semibold text-n-slate-12 tracking-[-0.005em]"
        >
          {{
            view === 'admin'
              ? $t('HOME_DASHBOARD_PAGE.TEAM_WORKLOAD.TITLE')
              : $t('HOME_DASHBOARD_PAGE.TOP_CONVERSATIONS.TITLE')
          }}
        </h2>
        <div v-on-click-outside="() => (sortOpen = false)" class="relative">
          <button
            type="button"
            class="inline-flex items-center gap-1.5 h-7 px-2.5 rounded-md border border-n-strong text-[12.5px] font-medium text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2 transition-colors bg-transparent cursor-pointer"
            @click.stop="sortOpen = !sortOpen"
          >
            <span class="text-n-slate-10 font-normal">
              {{ $t('HOME_DASHBOARD_PAGE.TEAM_WORKLOAD.SORT_BY') }}
            </span>
            <span>{{ sortByLabel }}</span>
            <span
              class="i-lucide-chevron-down size-3 text-n-slate-10 transition-transform"
              :class="{ 'rotate-180': sortOpen }"
            />
          </button>
          <div
            v-if="sortOpen"
            class="absolute right-0 top-[calc(100%+4px)] min-w-[160px] bg-n-solid-1 border border-n-strong rounded-lg p-1 shadow-xl z-30"
          >
            <button
              v-for="option in sortOptions"
              :key="option.key"
              type="button"
              class="flex items-center justify-between w-full gap-2 px-2 py-1.5 rounded text-[13px] text-left hover:bg-n-alpha-2 hover:text-n-slate-12 cursor-pointer bg-transparent border-0"
              :class="
                option.key === (view === 'admin' ? sortByKey : agentSortValue)
                  ? 'text-n-slate-12'
                  : 'text-n-slate-11'
              "
              @click="onSortSelect(option.key)"
            >
              <span>{{ option.label }}</span>
              <span
                v-if="
                  option.key === (view === 'admin' ? sortByKey : agentSortValue)
                "
                class="i-lucide-check size-3.5 text-n-brand"
              />
            </button>
          </div>
        </div>
      </div>

      <!-- Admin: team workload table -->
      <section
        v-if="view === 'admin'"
        class="mb-7 rounded-xl border border-n-strong bg-n-solid-1 overflow-hidden"
      >
        <div
          class="hidden md:grid grid-cols-[36px_1fr_140px_110px_90px_70px] items-center gap-4 px-[18px] py-2.5 border-b border-n-strong text-[11px] uppercase tracking-[0.06em] font-medium text-n-slate-10 bg-n-alpha-1"
        >
          <span />
          <span>
            {{ $t('HOME_DASHBOARD_PAGE.TEAM_WORKLOAD.HEADERS.AGENT') }}
          </span>
          <span>
            {{ $t('HOME_DASHBOARD_PAGE.TEAM_WORKLOAD.HEADERS.WORKLOAD') }}
          </span>
          <span>
            {{
              $t('HOME_DASHBOARD_PAGE.TEAM_WORKLOAD.HEADERS.UNATTENDED_OPEN')
            }}
          </span>
          <span>
            {{ $t('HOME_DASHBOARD_PAGE.TEAM_WORKLOAD.HEADERS.FRT') }}
          </span>
          <span>
            {{ $t('HOME_DASHBOARD_PAGE.TEAM_WORKLOAD.HEADERS.CSAT') }}
          </span>
        </div>
        <div
          v-for="agent in team"
          :key="agent.id"
          class="grid grid-cols-[36px_1fr_140px_110px_90px_70px] items-center gap-4 px-[18px] py-3.5 border-b border-n-strong last:border-b-0 hover:bg-n-alpha-1 cursor-pointer transition-colors"
        >
          <div
            class="size-8 rounded-full grid place-items-center text-white text-xs font-semibold relative flex-shrink-0"
            :style="{ background: agent.bg }"
          >
            {{ agent.initials }}
            <span
              class="absolute -bottom-px -right-px size-[9px] rounded-full border-2 border-n-solid-1"
              :class="{
                'bg-n-teal-9': agent.status === 'online',
                'bg-n-amber-9':
                  agent.status === 'busy' || agent.status === 'away',
                'bg-n-slate-8': !agent.status || agent.status === 'offline',
              }"
            />
          </div>
          <div>
            <div
              class="flex items-center gap-1.5 text-sm font-semibold text-n-slate-12"
            >
              {{ agent.name }}
              <span
                v-if="agent.isYou"
                class="text-[9.5px] font-semibold uppercase tracking-[0.08em] text-n-brand border border-n-brand/30 bg-n-brand/10 px-1 py-px rounded-sm"
              >
                {{ $t('HOME_DASHBOARD_PAGE.TEAM_WORKLOAD.YOU') }}
              </span>
            </div>
            <div class="text-[11.5px] text-n-slate-10 mt-0.5">
              {{ agent.sub }}
            </div>
          </div>
          <div class="flex flex-col gap-1">
            <div class="h-1 rounded-full bg-n-strong overflow-hidden">
              <span
                class="block h-full rounded-full"
                :class="{
                  'bg-n-teal-9': agent.capacityTone === 'ok',
                  'bg-n-amber-9': agent.capacityTone === 'warn',
                  'bg-n-ruby-9': agent.capacityTone === 'danger',
                  'bg-n-slate-7': agent.capacityTone === 'off',
                }"
                :style="{ width: `${agent.capacity}%` }"
              />
            </div>
            <span class="text-[11.5px] text-n-slate-11">
              {{
                agent.capacityTone === 'off'
                  ? $t('HOME_DASHBOARD_PAGE.TEAM_WORKLOAD.OFF_SHIFT')
                  : $t('HOME_DASHBOARD_PAGE.TEAM_WORKLOAD.CAPACITY', {
                      percent: agent.capacity,
                    })
              }}
            </span>
          </div>
          <div class="text-sm font-medium text-n-slate-12">
            {{ agent.primary }}
          </div>
          <div
            class="text-sm font-medium"
            :class="agent.frt === '—' ? 'text-n-slate-10' : 'text-n-slate-12'"
          >
            {{ agent.frt }}
          </div>
          <div
            class="text-sm font-medium"
            :class="{
              'text-n-teal-9': agent.csatTone === 'good',
              'text-n-ruby-9': agent.csatTone === 'alert',
              'text-n-slate-12': agent.csatTone === 'neutral',
            }"
          >
            {{ agent.csat }}
          </div>
        </div>
      </section>

      <!-- Admin: attention cards -->
      <template v-if="view === 'admin'">
        <div class="flex items-baseline justify-between mb-3.5">
          <h2
            class="m-0 text-sm font-semibold text-n-slate-12 tracking-[-0.005em]"
          >
            {{ $t('HOME_DASHBOARD_PAGE.ATTENTION.TITLE') }}
          </h2>
          <span class="text-xs text-n-slate-10">
            {{ $t('HOME_DASHBOARD_PAGE.ATTENTION.SUBTITLE') }}
          </span>
        </div>
        <section class="grid grid-cols-1 md:grid-cols-3 gap-3">
          <article
            v-for="card in attention"
            :key="card.title"
            class="flex flex-col gap-2.5 p-4 rounded-xl border border-n-strong bg-n-solid-1 hover:border-n-slate-6 cursor-pointer transition-colors group"
          >
            <div
              class="size-8 rounded-lg grid place-items-center flex-shrink-0"
              :class="{
                'bg-n-amber-3 text-n-amber-11': card.tone === 'amber',
                'bg-n-ruby-3 text-n-ruby-11': card.tone === 'rose',
                'bg-n-iris-3 text-n-iris-11': card.tone === 'iris',
              }"
            >
              <span class="size-4" :class="[card.icon]" />
            </div>
            <h3
              class="m-0 text-sm font-semibold text-n-slate-12 leading-tight tracking-[-0.005em]"
            >
              {{ card.title }}
            </h3>
            <p class="m-0 flex-1 text-[12.5px] text-n-slate-11 leading-snug">
              {{ card.body }}
            </p>
            <span
              class="inline-flex items-center gap-1 group-hover:gap-1.5 text-xs font-medium text-n-brand transition-[gap]"
            >
              {{ card.cta }}
              <span class="i-lucide-chevron-right size-3" />
            </span>
          </article>
        </section>
      </template>

      <!-- Agent: top conversations list -->
      <section
        v-else
        class="rounded-xl border border-n-strong bg-n-solid-1 overflow-hidden"
      >
        <div
          v-if="!conversations.length"
          class="px-[18px] py-10 text-center text-sm text-n-slate-10"
        >
          {{
            isLoadingMine
              ? $t('HOME_DASHBOARD_PAGE.TOP_CONVERSATIONS.LOADING')
              : $t('HOME_DASHBOARD_PAGE.TOP_CONVERSATIONS.EMPTY')
          }}
        </div>
        <router-link
          v-for="conv in conversations"
          :key="conv.conversationId"
          :to="
            accountScopedRoute('inbox_conversation', {
              conversation_id: conv.conversationId,
            })
          "
          class="grid grid-cols-[36px_1fr_auto] items-center gap-3.5 px-[18px] py-3.5 border-b border-n-strong last:border-b-0 hover:bg-n-alpha-1 cursor-pointer transition-colors"
        >
          <div
            class="size-8 rounded-full grid place-items-center text-white text-xs font-semibold flex-shrink-0"
            :style="{ background: conv.bg }"
          >
            {{ conv.initials }}
          </div>
          <div class="min-w-0">
            <div class="flex items-baseline gap-2 mb-0.5">
              <span
                class="text-sm font-semibold text-n-slate-12 tracking-[-0.005em]"
              >
                {{ conv.name }}
              </span>
              <span class="text-[11px] text-n-slate-9">{{ conv.id }}</span>
            </div>
            <MessagePreview
              v-if="conv.lastMessage"
              :message="conv.lastMessage"
              class="text-n-slate-11"
            />
          </div>
          <div class="flex items-center gap-3 flex-shrink-0">
            <CardPriorityIcon v-if="conv.priority" :priority="conv.priority" />
            <InboxName v-if="conv.inbox?.id" :inbox="conv.inbox" />
          </div>
        </router-link>
      </section>
    </div>
  </section>
</template>
