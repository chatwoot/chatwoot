<script setup>
import ContactPanel from 'dashboard/routes/dashboard/conversation/ContactPanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { computed } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';

const props = defineProps({
  currentChat: {
    required: true,
    type: Object,
  },
});

const getUIState = useMapGetter('uiState/getUIState');
const isCopilotSidebarOpen = computed(() =>
  getUIState.value('isCopilotSidebarOpen')
);
const isConversationSidebarOpen = computed(() =>
  getUIState.value('isConversationSidebarOpen')
);

const showConversationSidebar = computed(
  () =>
    props.currentChat.id &&
    !isCopilotSidebarOpen.value &&
    isConversationSidebarOpen.value
);

const store = useStore();
const closeConversationPanel = () => {
  store.dispatch('uiState/set', { isConversationSidebarOpen: false });
};
</script>

<template>
  <div
    v-if="showConversationSidebar"
    class="ltr:border-l rtl:border-r border-n-weak h-full overflow-hidden z-10 w-[20rem] min-w-[20rem] flex flex-col"
  >
    <div class="flex flex-1 flex-col overflow-auto">
      <div
        class="flex items-center justify-between gap-2 px-4 py-2 border-b border-n-weak h-12"
      >
        <span class="font-medium text-sm text-n-slate-12">
          {{ $t('CONVERSATION.SIDEBAR.ACTIONS') }}
        </span>
        <div class="flex items-center">
          <Button icon="i-lucide-x" ghost sm @click="closeConversationPanel" />
        </div>
      </div>
      <ContactPanel
        :conversation-id="props.currentChat.id"
        :inbox-id="props.currentChat.inbox_id"
      />
    </div>
  </div>
  <div v-else class="hidden" />
</template>
