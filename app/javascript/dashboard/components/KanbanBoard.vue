<script setup>
import { computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import KanbanColumn from './KanbanColumn.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import wootConstants from 'dashboard/constants/globals';

const props = defineProps({
  conversationInbox: { type: [String, Number], default: 0 },
  teamId: { type: [String, Number], default: 0 },
  label: { type: String, default: '' },
  conversationType: { type: String, default: '' },
  assigneeType: {
    type: String,
    default: wootConstants.ASSIGNEE_TYPE.ME,
  },
  sortBy: {
    type: String,
    default: wootConstants.SORT_BY_TYPE.LAST_ACTIVITY_AT_DESC,
  },
});

const store = useStore();
const { t } = useI18n();

const columns = computed(() => [
  { key: 'open', title: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.open.TEXT') },
  {
    key: 'pending',
    title: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.pending.TEXT'),
  },
  {
    key: 'snoozed',
    title: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.snoozed.TEXT'),
  },
  {
    key: 'resolved',
    title: t('CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.resolved.TEXT'),
  },
]);

const kanbanData = computed(() => store.state.conversations.kanbanData);
const isLoading = computed(() => store.getters.getChatListLoadingStatus);

const fetchParams = computed(() => ({
  inboxId: props.conversationInbox || undefined,
  teamId: props.teamId || undefined,
  labels: props.label ? [props.label] : undefined,
  conversationType: props.conversationType || undefined,
  assigneeType: props.assigneeType,
  sortBy: props.sortBy,
  perPage: 15,
}));

function fetchData() {
  store.dispatch('fetchKanbanData', fetchParams.value);
}

async function onStatusChange({ conversation, toStatus }) {
  const fromStatus = conversation.status;
  if (fromStatus === toStatus) return;

  // Optimistic update
  store.commit('MOVE_KANBAN_CONVERSATION', {
    conversationId: conversation.id,
    fromStatus,
    toStatus,
    conversation: { ...conversation, status: toStatus },
  });

  try {
    await store.dispatch('toggleStatus', {
      conversationId: conversation.id,
      status: toStatus,
    });
  } catch {
    // Revert on error
    store.commit('MOVE_KANBAN_CONVERSATION', {
      conversationId: conversation.id,
      fromStatus: toStatus,
      toStatus: fromStatus,
      conversation,
    });
  }
}

function onLoadMore(status) {
  const currentCount = kanbanData.value[status]?.conversations?.length || 0;
  const page = Math.ceil(currentCount / 15) + 1;

  store.dispatch('loadMoreKanbanColumn', {
    status,
    params: { ...fetchParams.value, page },
  });
}

onMounted(fetchData);

watch(
  () => [
    props.conversationInbox,
    props.teamId,
    props.label,
    props.assigneeType,
    props.sortBy,
  ],
  fetchData
);
</script>

<template>
  <div class="flex h-full gap-3 p-3 overflow-x-auto bg-n-solid-1">
    <div v-if="isLoading" class="flex items-center justify-center w-full">
      <Spinner class="size-6" />
    </div>
    <template v-else>
      <KanbanColumn
        v-for="col in columns"
        :key="col.key"
        :status="col.key"
        :title="col.title"
        :conversations="kanbanData[col.key]?.conversations || []"
        :count="kanbanData[col.key]?.meta?.count || 0"
        :has-more="kanbanData[col.key]?.meta?.has_more || false"
        @change="onStatusChange"
        @load-more="onLoadMore(col.key)"
      />
    </template>
  </div>
</template>
