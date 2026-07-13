<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ConversationTaskForm from './ConversationTaskForm.vue';
import ConversationTaskItem from './ConversationTaskItem.vue';

const props = defineProps({
  conversationId: { type: [String, Number], required: true },
});

const store = useStore();
const uiFlags = useMapGetter('internalTasks/getUIFlags');
const formRef = ref(null);

const tasks = computed(() =>
  store.getters['internalTasks/getConversationTasks'](props.conversationId)
);

const openCount = computed(() => tasks.value.length);

const fetchTasks = () => {
  store.dispatch('internalTasks/fetchConversationTasks', {
    conversationId: props.conversationId,
  });
};

const openForm = () => formRef.value?.open();

onMounted(() => {
  fetchTasks();
  store.dispatch('internalTasks/fetchTaskTemplates');
});
</script>

<template>
  <div>
    <div class="px-4 pt-3 pb-2 flex items-center justify-between gap-2">
      <p v-if="openCount" class="text-xs text-n-slate-11">
        {{ $t('INTERNAL_TASKS.PANEL.OPEN_COUNT', { count: openCount }) }}
      </p>
      <Button
        variant="ghost"
        size="xs"
        icon="i-lucide-plus"
        :label="$t('INTERNAL_TASKS.PANEL.NEW')"
        class="ml-auto"
        @click="openForm"
      />
    </div>

    <div v-if="uiFlags.isFetchingList" class="flex justify-center py-8">
      <Spinner />
    </div>

    <div
      v-else-if="!tasks.length"
      class="flex flex-col items-center gap-2 px-4 py-6 text-center"
    >
      <span
        class="size-10 rounded-full bg-n-alpha-2 flex items-center justify-center text-n-slate-11 i-lucide-clipboard-list"
      />
      <p class="text-sm text-n-slate-11">
        {{ $t('INTERNAL_TASKS.PANEL.EMPTY') }}
      </p>
      <Button
        variant="outline"
        size="sm"
        color="blue"
        icon="i-lucide-plus"
        :label="$t('INTERNAL_TASKS.PANEL.CREATE_FIRST')"
        @click="openForm"
      />
    </div>

    <div
      v-else
      class="max-h-[320px] overflow-y-auto px-4 pb-4 flex flex-col gap-2"
    >
      <ConversationTaskItem
        v-for="task in tasks"
        :key="task.id"
        :task="task"
        :conversation-id="conversationId"
        compact
        @updated="fetchTasks"
      />
    </div>

    <ConversationTaskForm
      ref="formRef"
      :conversation-id="conversationId"
      @created="fetchTasks"
    />
  </div>
</template>
