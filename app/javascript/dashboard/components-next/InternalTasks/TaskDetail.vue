<script setup>
import { computed, ref, watch, onMounted, onUnmounted, nextTick } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { frontendURL, taskListPageURL } from 'dashboard/helper/URLHelper';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ConversationTaskForm from './ConversationTaskForm.vue';
import TaskDetailHeader from './TaskDetailHeader.vue';
import TaskDetailOverview from './TaskDetailOverview.vue';
import TaskAnchoredMessage from './TaskAnchoredMessage.vue';
import TaskActivityLog from './TaskActivityLog.vue';
import TaskDetailConversation from './TaskDetailConversation.vue';

const props = defineProps({
  taskId: { type: [String, Number], required: true },
  isOnExpandedLayout: { type: Boolean, default: false },
});

const emit = defineEmits(['updated']);
const route = useRoute();
const router = useRouter();
const store = useStore();
const uiFlags = useMapGetter('internalTasks/getUIFlags');
const task = useMapGetter('internalTasks/getSelectedTask');
const currentChat = useMapGetter('getSelectedChat');
const taskFormRef = ref(null);

const activeIndex = ref(0);
const conversationLoaded = ref(false);
const conversationLoading = ref(false);

const conversationDisplayId = computed(() => task.value?.conversation?.id);
const sourceMessage = computed(() => task.value?.sourceMessage || null);
const taskEvents = computed(() => task.value?.events || []);

const scrollToSourceMessage = async () => {
  const messageId = task.value?.sourceMessageId;
  if (!messageId) return;
  await nextTick();
  emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, { messageId });
};

const loadTask = () => {
  store.dispatch('internalTasks/fetchTask', { taskId: props.taskId });
};

const loadConversation = async () => {
  const displayId = conversationDisplayId.value;
  if (!displayId) return;

  conversationLoading.value = true;
  try {
    let chat = store.getters.getConversationById(displayId);
    if (!chat?.id) {
      await store.dispatch('getConversation', displayId);
      chat = store.getters.getConversationById(displayId);
    }
    if (chat?.id && chat.id !== currentChat.value?.id) {
      await store.dispatch('setActiveChat', { data: chat });
    }
    await scrollToSourceMessage();
    conversationLoaded.value = true;
  } finally {
    conversationLoading.value = false;
  }
};

const onTabChange = async index => {
  activeIndex.value = index;
  if (index === 1 && !conversationLoaded.value) {
    await loadConversation();
  }
};

const jumpToMessage = async () => {
  activeIndex.value = 1;
  if (!conversationLoaded.value) {
    await loadConversation();
  } else {
    await scrollToSourceMessage();
  }
};

const resetTabState = () => {
  activeIndex.value = 0;
  conversationLoaded.value = false;
};

const onTaskUpdated = () => {
  loadTask();
  emit('updated');
};

const goBack = () => {
  router.push({
    path: frontendURL(taskListPageURL({ accountId: route.params.accountId })),
  });
};

const openTaskFormFromMessage = message => {
  const conversationId = message.conversationId ?? message.conversation_id;
  taskFormRef.value?.open({
    conversationId,
    sourceMessageId: message.id,
    anchorMessage: message,
  });
};

watch(
  () => props.taskId,
  () => {
    resetTabState();
    loadTask();
  }
);

onMounted(() => {
  loadTask();
  emitter.on(BUS_EVENTS.CREATE_TASK_FROM_MESSAGE, openTaskFormFromMessage);
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.CREATE_TASK_FROM_MESSAGE, openTaskFormFromMessage);
});
</script>

<template>
  <div
    class="conversation-details-wrap flex flex-col flex-1 min-w-0 h-full bg-n-surface-1 relative"
    :class="{
      'border-l rtl:border-l-0 rtl:border-r border-n-weak': !isOnExpandedLayout,
    }"
  >
    <div
      v-if="isOnExpandedLayout"
      class="flex items-center gap-2 px-4 py-2 border-b border-n-weak"
    >
      <Button
        variant="ghost"
        size="sm"
        icon="i-lucide-arrow-left"
        :label="$t('INTERNAL_TASKS.INBOX.BACK_TO_LIST')"
        @click="goBack"
      />
    </div>

    <div
      v-if="uiFlags.isFetchingTask && !task"
      class="flex justify-center py-16"
    >
      <Spinner />
    </div>

    <template v-else-if="task">
      <woot-tabs
        :index="activeIndex"
        class="shrink-0 border-b border-n-weak"
        @change="onTabChange"
      >
        <woot-tabs-item
          :index="0"
          :name="$t('INTERNAL_TASKS.TABS.TASK')"
          :show-badge="false"
          is-compact
        />
        <woot-tabs-item
          :index="1"
          :name="$t('INTERNAL_TASKS.TABS.CONVERSATION')"
          :show-badge="false"
          is-compact
        />
      </woot-tabs>

      <div
        v-show="activeIndex === 0"
        class="flex flex-col flex-1 min-h-0 overflow-y-auto"
      >
        <TaskDetailHeader
          :task="task"
          :conversation-id="conversationDisplayId"
          @updated="onTaskUpdated"
        />
        <TaskDetailOverview :task="task" compact />
        <TaskAnchoredMessage
          v-if="sourceMessage"
          :message="sourceMessage"
          @jump="jumpToMessage"
        />
        <TaskActivityLog
          :events="taskEvents"
          :task-id="task.id"
          :conversation-id="conversationDisplayId"
          @updated="onTaskUpdated"
        />
      </div>

      <div v-show="activeIndex === 1" class="flex flex-col flex-1 min-h-0">
        <TaskDetailConversation :is-loading="conversationLoading" />
      </div>
    </template>

    <ConversationTaskForm
      v-if="conversationDisplayId"
      ref="taskFormRef"
      :conversation-id="conversationDisplayId"
      @created="onTaskUpdated"
    />
  </div>
</template>
