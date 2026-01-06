<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store.js';
import { useUISettings } from 'dashboard/composables/useUISettings';

import KanbanBoard from 'dashboard/components/KanbanBoard.vue';
import ChatTypeTabs from 'dashboard/components/widgets/ChatTypeTabs.vue';
import ConversationBasicFilter from 'dashboard/components/widgets/conversation/ConversationBasicFilter.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

import wootConstants from 'dashboard/constants/globals';
import {
  getUserPermissions,
  filterItemsByPermission,
} from 'dashboard/helper/permissionsHelper.js';
import { ASSIGNEE_TYPE_TAB_PERMISSIONS } from 'dashboard/constants/permissions.js';

const props = defineProps({
  inboxId: { type: [String, Number], default: 0 },
  label: { type: String, default: '' },
  teamId: { type: String, default: '' },
});

const store = useStore();
const router = useRouter();
const { t } = useI18n();
const { uiSettings } = useUISettings();

const activeAssigneeTab = ref(wootConstants.ASSIGNEE_TYPE.ME);
const activeStatus = ref(wootConstants.STATUS_TYPE.OPEN);
const activeSortBy = ref(wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC);

const currentUser = useMapGetter('getCurrentUser');
const currentAccountId = useMapGetter('getCurrentAccountId');
const conversationStats = useMapGetter('conversationStats/getStats');
const activeInbox = useMapGetter('getSelectedInbox');
const getTeamFn = useMapGetter('teams/getTeam');

const inbox = computed(
  () => store.getters['inboxes/getInbox'](activeInbox.value) || {}
);

const activeTeam = computed(() => {
  if (props.teamId) {
    return getTeamFn.value(props.teamId);
  }
  return {};
});

const userPermissions = computed(() => {
  return getUserPermissions(currentUser.value, currentAccountId.value);
});

const assigneeTabItems = computed(() => {
  return filterItemsByPermission(
    ASSIGNEE_TYPE_TAB_PERMISSIONS,
    userPermissions.value,
    item => item.permissions
  ).map(({ key, count: countKey }) => ({
    key,
    name: t(`CHAT_LIST.ASSIGNEE_TYPE_TABS.${key}`),
    count: conversationStats.value[countKey] || 0,
  }));
});

const pageTitle = computed(() => {
  if (inbox.value.name) {
    return inbox.value.name;
  }
  if (activeTeam.value?.name) {
    return activeTeam.value.name;
  }
  if (props.label) {
    return `#${props.label}`;
  }
  return t('CHAT_LIST.TAB_HEADING');
});

function setFiltersFromUISettings() {
  const { conversations_filter_by: filterBy = {} } = uiSettings.value;
  const { status, order_by: orderBy } = filterBy;
  activeStatus.value = status || wootConstants.STATUS_TYPE.OPEN;
  activeSortBy.value = Object.values(wootConstants.SORT_BY_TYPE).includes(
    orderBy
  )
    ? orderBy
    : wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC;
}

function updateAssigneeTab(selectedTab) {
  if (activeAssigneeTab.value !== selectedTab) {
    activeAssigneeTab.value = selectedTab;
  }
}

function onBasicFilterChange(value, type) {
  if (type === 'status') {
    activeStatus.value = value;
  } else {
    activeSortBy.value = value;
  }
}

function navigateToList() {
  router.push({ name: 'home' });
}

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('labels/get');
  store.dispatch('inboxes/get');
  store.dispatch('setActiveInbox', props.inboxId);
  setFiltersFromUISettings();

  // Fetch conversation stats
  store.dispatch('conversationStats/get', {
    inboxId: props.inboxId || undefined,
    assigneeType: activeAssigneeTab.value,
    status: activeStatus.value,
  });
});

watch(
  () => [props.inboxId, props.teamId, props.label],
  () => {
    store.dispatch('setActiveInbox', props.inboxId);
  }
);
</script>

<template>
  <section class="flex flex-col w-full h-full bg-n-solid-1">
    <!-- Header -->
    <div
      class="flex items-center justify-between gap-2 px-4 py-3 border-b border-n-weak"
    >
      <div class="flex items-center gap-3">
        <NextButton
          v-tooltip.right="$t('CHAT_LIST.SWITCH_TO_LIST')"
          icon="i-lucide-arrow-left"
          slate
          sm
          faded
          @click="navigateToList"
        />
        <h1 class="text-lg font-semibold text-n-slate-12">
          {{ pageTitle }}
        </h1>
      </div>
      <div class="flex items-center gap-2">
        <ConversationBasicFilter
          is-on-expanded-layout
          @change-filter="onBasicFilterChange"
        />
      </div>
    </div>

    <!-- Assignee Tabs -->
    <ChatTypeTabs
      :items="assigneeTabItems"
      :active-tab="activeAssigneeTab"
      is-compact
      class="border-b border-n-weak"
      @chat-tab-change="updateAssigneeTab"
    />

    <!-- Full-width Kanban Board -->
    <KanbanBoard
      :conversation-inbox="inboxId"
      :team-id="teamId"
      :label="label"
      :assignee-type="activeAssigneeTab"
      :sort-by="activeSortBy"
      class="flex-1"
    />
  </section>
</template>
