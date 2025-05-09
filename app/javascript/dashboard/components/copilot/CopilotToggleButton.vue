<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useRoute } from 'vue-router';
import Button from 'dashboard/components-next/button/Button.vue';
import { useMapGetter } from 'dashboard/composables/store';

const store = useStore();
const route = useRoute();

const getUIState = useMapGetter('uiState/getUIState');
const isSidebarOpen = computed(() => getUIState.value('isCopilotSidebarOpen'));

const isConversationRoute = computed(() => {
  const CONVERSATION_ROUTES = [
    'inbox_conversation',
    'conversation_through_inbox',
    'conversations_through_label',
    'team_conversations_through_label',
    'conversations_through_folders',
    'conversation_through_mentions',
    'conversation_through_unattended',
    'conversation_through_participating',
  ];
  return CONVERSATION_ROUTES.includes(route.name);
});

const toggleSidebar = () => {
  store.dispatch('uiState/toggle', 'isCopilotSidebarOpen');
};
</script>

<template>
  <div class="fixed bottom-4 right-4 z-50">
    <Button
      v-if="!isSidebarOpen && !isConversationRoute"
      icon="i-woot-captain"
      class="!rounded-full bg-n-iris-9 text-xl"
      lg
      @click="toggleSidebar"
    />
  </div>
</template>
