<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useStore } from 'dashboard/composables/store';
import ConversationApi from 'dashboard/api/conversations';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();

const queue = ref(null);
const isLoading = ref(false);
const isLeaving = ref(false);

const queueEnabled = computed(() => currentAccount.value?.queue_enabled);

const statusLabel = computed(() => {
  if (!queue.value) {
    return t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.STATUS.NONE');
  }

  const statusMap = {
    waiting: t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.STATUS.WAITING'),
    assigned: t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.STATUS.ASSIGNED'),
    left: t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.STATUS.LEFT'),
  };

  return (
    statusMap[queue.value.status] ||
    t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.STATUS.NONE')
  );
});

const canLeaveQueue = computed(() => queue.value?.status === 'waiting');

const fetchQueue = async () => {
  if (!props.conversationId || !queueEnabled.value) {
    queue.value = null;
    return;
  }

  isLoading.value = true;
  try {
    const response = await ConversationApi.getQueue(props.conversationId);
    queue.value = response.data.queue;
  } catch (error) {
    queue.value = null;
    useAlert(t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.LOAD_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const leaveQueue = async () => {
  if (!canLeaveQueue.value || isLeaving.value) return;

  isLeaving.value = true;
  try {
    const response = await ConversationApi.leaveQueue(props.conversationId);
    queue.value = response.data.queue;
    useAlert(t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.LEAVE_SUCCESS'));
    store.dispatch('fetchConversation', props.conversationId);
  } catch (error) {
    useAlert(
      error?.response?.data?.error ||
        t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.LEAVE_ERROR')
    );
  } finally {
    isLeaving.value = false;
  }
};

watch(
  () => props.conversationId,
  () => {
    fetchQueue();
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-3 px-2 py-1">
    <div v-if="!queueEnabled" class="text-sm text-n-slate-11">
      {{ $t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.EMPTY') }}
    </div>
    <template v-else>
      <div class="flex flex-col gap-1">
        <span class="text-xs font-medium text-n-slate-11">
          {{ $t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.STATUS_LABEL') }}
        </span>
        <span class="text-sm text-n-slate-12">
          <span v-if="isLoading">{{
            $t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.LOADING')
          }}</span>
          <span v-else>{{ statusLabel }}</span>
        </span>
      </div>

      <div
        v-if="queue?.status === 'waiting' && queue?.position"
        class="flex flex-col gap-1"
      >
        <span class="text-xs font-medium text-n-slate-11">
          {{ $t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.POSITION') }}
        </span>
        <span class="text-sm text-n-slate-12">{{ queue.position }}</span>
      </div>

      <p v-if="!isLoading && !queue" class="text-sm text-n-slate-11">
        {{ $t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.EMPTY') }}
      </p>

      <NextButton
        v-if="canLeaveQueue"
        ruby
        sm
        :is-loading="isLeaving"
        :label="$t('CONVERSATION_SIDEBAR.QUEUE_ACTIONS.LEAVE')"
        icon="i-lucide-list-x"
        @click="leaveQueue"
      />
    </template>
  </div>
</template>
