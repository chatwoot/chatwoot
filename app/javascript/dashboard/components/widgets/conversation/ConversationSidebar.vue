<script setup>
import { computed } from 'vue';
import CopilotContainer from '../../copilot/CopilotContainer.vue';
import ContactPanel from 'dashboard/routes/dashboard/conversation/ContactPanel.vue';
import { useMapGetter } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from '../../../featureFlags';
import { useUISettings } from 'dashboard/composables/useUISettings';

const props = defineProps({
  currentChat: {
    required: true,
    type: Object,
  },
});

const channelType = computed(() => props.currentChat?.meta?.channel || '');

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const showCopilotTab = computed(() =>
  isFeatureEnabledonAccount.value(currentAccountId.value, FEATURE_FLAGS.CAPTAIN)
);

const { uiSettings } = useUISettings();

const activeTab = computed(() => {
  const {
    is_contact_sidebar_open: isContactSidebarOpen,
    is_copilot_panel_open: isCopilotPanelOpen,
  } = uiSettings.value;

  if (isContactSidebarOpen) {
    return 0;
  }
  if (isCopilotPanelOpen) {
    return 1;
  }
  return null;
});
</script>

<template>
  <div
    class="ltr:border-l rtl:border-r border-n-weak h-full overflow-hidden z-10 w-[320px] min-w-[320px] 2xl:min-w-[360px] 2xl:w-[360px] flex flex-col bg-n-background"
  >
    <div class="flex flex-1 overflow-auto">
      <ContactPanel
        v-show="activeTab === 0"
        :conversation-id="currentChat.id"
        :inbox-id="currentChat.inbox_id"
      />
      <CopilotContainer
        v-show="activeTab === 1 && showCopilotTab"
        :key="currentChat.id"
        :conversation-inbox-type="channelType"
        :conversation-id="currentChat.id"
        class="flex-1"
      />
    </div>
  </div>
</template>
