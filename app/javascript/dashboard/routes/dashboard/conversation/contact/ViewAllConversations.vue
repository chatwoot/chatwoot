<script setup>
import { computed, inject } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { CONTACT_CONVERSATION_NAVIGATION } from 'dashboard/composables/useContactConversationNavigation';
import { useConversationRoutePath } from 'dashboard/composables/useConversationRoutePath';
import { useUISettings } from 'dashboard/composables/useUISettings';
import NextButton from 'dashboard/components-next/button/Button.vue';

const route = useRoute();
const navigation = inject(CONTACT_CONVERSATION_NAVIGATION, null);
const { buildConversationPath, buildConversationListPath, isOnFolderView } =
  useConversationRoutePath();
const { isOnExpandedLayout } = useUISettings();
const selectedChat = useMapGetter('getSelectedChat');

// The inbox view has no list to scope, so the history opens in the conversation view.
const isOnInboxView = computed(() =>
  String(route.name || '').startsWith('inbox_view')
);

const viewAllConversations = () => {
  // The expanded layout moves to the list, so there is no open thread left to keep.
  if (isOnExpandedLayout.value) {
    return navigation.viewContactHistory({
      path: buildConversationListPath({ keepFolderScope: false }),
    });
  }

  const conversationId = selectedChat.value?.id;
  return navigation.viewContactHistory({
    conversationId,
    // A folder narrows the list to its own query, so the history has to leave that scope.
    path:
      isOnFolderView.value || isOnInboxView.value
        ? buildConversationPath(conversationId, { keepFolderScope: false })
        : null,
  });
};
</script>

<template>
  <NextButton
    v-if="navigation?.hasHistory.value"
    v-tooltip.top-end="$t('CONTACT_PANEL.CONVERSATIONS.VIEW_ALL')"
    :aria-label="$t('CONTACT_PANEL.CONVERSATIONS.VIEW_ALL')"
    icon="i-ph-clock-counter-clockwise"
    slate
    faded
    sm
    @click="viewAllConversations"
  />
</template>
