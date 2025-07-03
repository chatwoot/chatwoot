<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { computed, defineProps } from 'vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { useMapGetter } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

const props = defineProps({
  currentChat: {
    required: true,
    type: Object,
  },
});

const { updateUISettings } = useUISettings();

const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const channelType = computed(() => {
  return props.currentChat?.channel || props.currentChat?.meta?.channel || '';
});

const showCopilotTab = computed(() =>
  isFeatureEnabledonAccount.value(currentAccountId.value, FEATURE_FLAGS.CAPTAIN)
);

const showShopeeTab = computed(() => channelType.value === INBOX_TYPES.SHOPEE);

const { uiSettings } = useUISettings();
const isContactSidebarOpen = computed(
  () => uiSettings.value.is_contact_sidebar_open
);
const isCopilotPanelOpen = computed(
  () => uiSettings.value.is_copilot_panel_open
);
const isShopeePanelOpen = computed(() => uiSettings.value.is_shopee_panel_open);

const toggleConversationSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: !isContactSidebarOpen.value,
    is_copilot_panel_open: false,
    is_shopee_panel_open: false,
  });
};

const handleConversationSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: true,
    is_copilot_panel_open: false,
    is_shopee_panel_open: false,
  });
};

const handleCopilotSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: false,
    is_copilot_panel_open: true,
    is_shopee_panel_open: false,
  });
};

const handleShopeeSidebarToggle = () => {
  updateUISettings({
    is_contact_sidebar_open: false,
    is_copilot_panel_open: false,
    is_shopee_panel_open: true,
  });
};

const keyboardEvents = {
  'Alt+KeyO': {
    action: toggleConversationSidebarToggle,
  },
};
useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div
    class="flex flex-col justify-center items-center absolute top-36 xl:top-24 ltr:right-2 rtl:left-2 bg-n-solid-2 border border-n-weak rounded-full gap-2 p-1"
  >
    <Button
      v-tooltip.top="$t('CONVERSATION.SIDEBAR.CONTACT')"
      ghost
      slate
      sm
      class="!rounded-full"
      :class="{
        'bg-n-alpha-2': isContactSidebarOpen,
      }"
      icon="i-ph-user-bold"
      @click="handleConversationSidebarToggle"
    />
    <Button
      v-if="showCopilotTab"
      v-tooltip.bottom="$t('CONVERSATION.SIDEBAR.COPILOT')"
      ghost
      slate
      class="!rounded-full"
      :class="{
        'bg-n-alpha-2 !text-n-iris-9': isCopilotPanelOpen,
      }"
      sm
      icon="i-woot-captain"
      @click="handleCopilotSidebarToggle"
    />
    <Button
      v-if="showShopeeTab"
      v-tooltip.bottom="$t('CONVERSATION.SIDEBAR.SHOPEE')"
      ghost
      slate
      class="!rounded-full"
      :class="{
        'bg-n-alpha-2 !text-n-iris-9': isShopeePanelOpen,
      }"
      sm
      icon="i-woot-shopee"
      @click="handleShopeeSidebarToggle"
    />
  </div>
</template>
