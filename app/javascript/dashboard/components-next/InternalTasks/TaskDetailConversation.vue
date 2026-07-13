<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import MessagesView from 'dashboard/components/widgets/conversation/MessagesView.vue';

defineProps({
  isLoading: { type: Boolean, default: false },
});

const currentChat = useMapGetter('getSelectedChat');
const inboxId = computed(() => currentChat.value?.inbox_id);
</script>

<template>
  <div class="flex flex-col flex-1 min-h-0">
    <div v-if="isLoading" class="flex flex-1 items-center justify-center">
      <Spinner />
    </div>
    <MessagesView
      v-else-if="currentChat?.id"
      class="flex-1 min-h-0"
      :inbox-id="inboxId"
    />
    <div
      v-else
      class="flex flex-1 items-center justify-center text-sm text-n-slate-11"
    >
      {{ $t('INTERNAL_TASKS.TABS.CONVERSATION_EMPTY') }}
    </div>
  </div>
</template>
