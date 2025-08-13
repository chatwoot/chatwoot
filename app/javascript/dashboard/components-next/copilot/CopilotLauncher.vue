<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import Button from 'dashboard/components-next/button/Button.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useMapGetter } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
const route = useRoute();

const { uiSettings, updateUISettings } = useUISettings();

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
    'inbox_view_conversation',
  ];
  return CONVERSATION_ROUTES.includes(route.name);
});

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const showCopilotLauncher = computed(() => {
  const isCaptainEnabled = isFeatureEnabledonAccount.value(
    currentAccountId.value,
    FEATURE_FLAGS.CAPTAIN
  );
  return (
    isCaptainEnabled &&
    !uiSettings.value.is_copilot_panel_open &&
    !isConversationRoute.value
  );
});
const toggleSidebar = () => {
  updateUISettings({
    is_copilot_panel_open: !uiSettings.value.is_copilot_panel_open,
    is_contact_sidebar_open: false,
  });
};
</script>

<template>
  <div
    v-if="showCopilotLauncher"
    class="fixed bottom-4 ltr:right-4 rtl:left-4 z-50"
  >
    <div class="rounded-full bg-n-alpha-2 p-1">
      <Button
        icon="i-woot-captain"
        class="!rounded-full !bg-n-solid-3 dark:!bg-n-alpha-2 !text-n-slate-12 text-xl"
        lg
        @click="toggleSidebar"
      />
    </div>
  </div>
  <template v-else />
</template>
