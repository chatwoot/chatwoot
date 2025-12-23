<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import ConversationApi from 'dashboard/api/inbox/conversation';
import wootConstants from 'dashboard/constants/globals';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const { t } = useI18n();
const router = useRouter();
const store = useStore();
const { accountId } = useAccount();

const conversations = ref([]);
const isLoading = ref(false);
const currentPage = ref(1);
const totalCount = ref(0);

const filters = ref({
  status: wootConstants.STATUS_TYPE.OPEN,
  assigneeType: wootConstants.ASSIGNEE_TYPE.ALL,
  inboxId: null,
  assigneeId: null,
  dateFrom: null,
  dateTo: null,
});

const inboxes = useMapGetter('inboxes/getInboxes');
const agents = useMapGetter('agents/getAgents');

const fetchConversations = async () => {
  isLoading.value = true;
  try {
    const params = {
      status: filters.value.status,
      assignee_type: filters.value.assigneeType,
      inbox_id: filters.value.inboxId,
      page: currentPage.value,
    };

    if (filters.value.assigneeId) {
      params.assignee_type = 'assigned';
      // Note: API doesn't directly support assignee_id filter,
      // we'll filter on the frontend or use a different approach
    }

    const response = await ConversationApi.get(params);
    conversations.value = response.data.payload || [];
    totalCount.value = response.data.meta?.count || 0;
  } catch (error) {
    console.error('Error fetching conversations:', error);
  } finally {
    isLoading.value = false;
  }
};

const openConversation = conversation => {
  router.push({
    name: 'inbox_view_conversation',
    params: {
      type: 'conversation',
      id: conversation.id,
    },
  });
};

const assignConversation = async (conversationId, agentId) => {
  try {
    await ConversationApi.assignAgent({
      conversationId,
      agentId,
    });
    await fetchConversations();
  } catch (error) {
    console.error('Error assigning conversation:', error);
  }
};

const resolveConversation = async conversationId => {
  try {
    await ConversationApi.toggleStatus({
      conversationId,
      status: 'resolved',
    });
    await fetchConversations();
  } catch (error) {
    console.error('Error resolving conversation:', error);
  }
};

const filteredConversations = computed(() => {
  let result = conversations.value;

  if (filters.value.assigneeId) {
    result = result.filter(
      conv => conv.meta?.assignee?.id === Number(filters.value.assigneeId)
    );
  }

  if (filters.value.dateFrom) {
    const dateFrom = new Date(filters.value.dateFrom);
    result = result.filter(
      conv => new Date(conv.last_activity_at) >= dateFrom
    );
  }

  if (filters.value.dateTo) {
    const dateTo = new Date(filters.value.dateTo);
    dateTo.setHours(23, 59, 59, 999);
    result = result.filter(
      conv => new Date(conv.last_activity_at) <= dateTo
    );
  }

  return result;
});

const getInboxName = inboxId => {
  const inbox = inboxes.value.find(i => i.id === inboxId);
  return inbox?.name || '-';
};

const getAssigneeName = conversation => {
  return conversation.meta?.assignee?.name || t('ADMIN.UNASSIGNED');
};

watch(filters, () => {
  currentPage.value = 1;
  fetchConversations();
}, { deep: true });

onMounted(async () => {
  await store.dispatch('inboxes/get');
  await store.dispatch('agents/get');
  await fetchConversations();
});
</script>

<template>
  <div class="flex flex-col h-full w-full bg-n-solid-1">
    <div class="flex flex-col gap-6 p-8">
      <div class="flex flex-col gap-2">
        <h1 class="text-2xl font-semibold text-n-slate-12">
          {{ t('ADMIN.CONVERSATIONS_TITLE') }}
        </h1>
        <p class="text-sm text-n-slate-11">
          {{ t('ADMIN.CONVERSATIONS_DESCRIPTION') }}
        </p>
      </div>

      <!-- Filters -->
      <div class="flex flex-wrap gap-4 p-4 rounded-lg border border-n-weak bg-n-solid-2">
        <div class="flex flex-col gap-1 min-w-[200px]">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('ADMIN.FILTER_STATUS') }}
          </label>
          <select
            v-model="filters.status"
            class="px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
          >
            <option :value="wootConstants.STATUS_TYPE.ALL">
              {{ t('ADMIN.STATUS_ALL') }}
            </option>
            <option :value="wootConstants.STATUS_TYPE.OPEN">
              {{ t('ADMIN.STATUS_OPEN') }}
            </option>
            <option :value="wootConstants.STATUS_TYPE.PENDING">
              {{ t('ADMIN.STATUS_PENDING') }}
            </option>
            <option :value="wootConstants.STATUS_TYPE.RESOLVED">
              {{ t('ADMIN.STATUS_RESOLVED') }}
            </option>
          </select>
        </div>

        <div class="flex flex-col gap-1 min-w-[200px]">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('ADMIN.FILTER_INBOX') }}
          </label>
          <select
            v-model="filters.inboxId"
            class="px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
          >
            <option :value="null">{{ t('ADMIN.ALL_INBOXES') }}</option>
            <option
              v-for="inbox in inboxes"
              :key="inbox.id"
              :value="inbox.id"
            >
              {{ inbox.name }}
            </option>
          </select>
        </div>

        <div class="flex flex-col gap-1 min-w-[200px]">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('ADMIN.FILTER_ASSIGNEE') }}
          </label>
          <select
            v-model="filters.assigneeId"
            class="px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
          >
            <option :value="null">{{ t('ADMIN.ALL_ASSIGNEES') }}</option>
            <option
              v-for="agent in agents"
              :key="agent.id"
              :value="agent.id"
            >
              {{ agent.name }}
            </option>
          </select>
        </div>

        <div class="flex flex-col gap-1 min-w-[200px]">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('ADMIN.FILTER_DATE_FROM') }}
          </label>
          <input
            v-model="filters.dateFrom"
            type="date"
            class="px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
          />
        </div>

        <div class="flex flex-col gap-1 min-w-[200px]">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('ADMIN.FILTER_DATE_TO') }}
          </label>
          <input
            v-model="filters.dateTo"
            type="date"
            class="px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
          />
        </div>
      </div>

      <!-- Conversations List -->
      <div class="flex flex-col gap-2">
        <div class="flex items-center justify-between">
          <p class="text-sm text-n-slate-11">
            {{ t('ADMIN.TOTAL_CONVERSATIONS', { count: filteredConversations.length }) }}
          </p>
        </div>

        <div
          v-if="isLoading"
          class="flex items-center justify-center p-8"
        >
          <Spinner />
        </div>

        <div
          v-else-if="filteredConversations.length === 0"
          class="flex flex-col items-center justify-center p-8 gap-2"
        >
          <p class="text-sm text-n-slate-11">
            {{ t('ADMIN.NO_CONVERSATIONS_FOUND') }}
          </p>
        </div>

        <div
          v-else
          class="flex flex-col gap-2"
        >
          <div
            v-for="conversation in filteredConversations"
            :key="conversation.id"
            class="flex items-center gap-4 p-4 rounded-lg border border-n-weak bg-n-solid-2 hover:bg-n-solid-3 transition-colors cursor-pointer"
            @click="openConversation(conversation)"
          >
            <div class="flex flex-col flex-1 gap-1 min-w-0">
              <div class="flex items-center gap-2">
                <span class="text-sm font-medium text-n-slate-12 truncate">
                  {{ conversation.meta?.sender?.name || conversation.meta?.sender?.email || '-' }}
                </span>
                <span class="text-xs text-n-slate-10">
                  #{{ conversation.display_id }}
                </span>
              </div>
              <p class="text-xs text-n-slate-11 truncate">
                {{ conversation.meta?.last_non_activity_message || '-' }}
              </p>
              <div class="flex items-center gap-4 text-xs text-n-slate-10">
                <span>{{ getInboxName(conversation.inbox_id) }}</span>
                <span>{{ t('ADMIN.ASSIGNED_TO') }}: {{ getAssigneeName(conversation) }}</span>
                <span>{{ conversation.status }}</span>
              </div>
            </div>
            <div class="flex gap-2 flex-shrink-0">
              <Button
                size="sm"
                variant="ghost"
                @click.stop="() => resolveConversation(conversation.id)"
              >
                {{ t('ADMIN.RESOLVE') }}
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

