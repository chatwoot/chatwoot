<script setup>
import '@chatwoot/ninja-keys';
import { ref, computed, watchEffect, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useTrack } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useAppearanceHotKeys } from 'dashboard/composables/commands/useAppearanceHotKeys';
import { useInboxHotKeys } from 'dashboard/composables/commands/useInboxHotKeys';
import { useGoToCommandHotKeys } from 'dashboard/composables/commands/useGoToCommandHotKeys';
import { useBulkActionsHotKeys } from 'dashboard/composables/commands/useBulkActionsHotKeys';
import { useConversationHotKeys } from 'dashboard/composables/commands/useConversationHotKeys';
import wootConstants from 'dashboard/constants/globals';
import { GENERAL_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

const store = useStore();
const { t } = useI18n();

const ninjakeys = ref(null);

// Added selectedSnoozeType to track the selected snooze type
// So if the selected snooze type is "custom snooze" then we set selectedSnoozeType with the CMD action id
// So that we can track the selected snooze type and when we close the command bar
const selectedSnoozeType = ref(null);

const { goToAppearanceHotKeys } = useAppearanceHotKeys();
const { inboxHotKeys } = useInboxHotKeys();
const { goToCommandHotKeys } = useGoToCommandHotKeys();
const { bulkActionsHotKeys } = useBulkActionsHotKeys();
const { conversationHotKeys } = useConversationHotKeys();

const placeholder = computed(() => t('COMMAND_BAR.SEARCH_PLACEHOLDER'));

const hotKeys = computed(() => [
  ...inboxHotKeys.value,
  ...goToCommandHotKeys.value,
  ...goToAppearanceHotKeys.value,
  ...bulkActionsHotKeys.value,
  ...conversationHotKeys.value,
]);

const setCommandBarData = () => {
  ninjakeys.value.data = hotKeys.value;
};

const onSelected = item => {
  const {
    detail: { action: { title = null, section = null, id = null } = {} } = {},
  } = item;
  // Added this condition to prevent setting the selectedSnoozeType to null
  // When we select the "custom snooze" (CMD bar will close and the custom snooze modal will open)
  if (id === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
    selectedSnoozeType.value = wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME;
  } else {
    selectedSnoozeType.value = null;
  }

  useTrack(GENERAL_EVENTS.COMMAND_BAR, {
    section,
    action: title,
  });

  setCommandBarData();
};

const onClosed = () => {
  // If the selectedSnoozeType is not "SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME (custom snooze)" then we set the context menu chat id to null
  // Else we do nothing and its handled in the ChatList.vue hideCustomSnoozeModal() method
  if (
    selectedSnoozeType.value !== wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME
  ) {
    store.dispatch('setContextMenuChatId', null);
  }
};

watchEffect(() => {
  if (ninjakeys.value) {
    ninjakeys.value.data = hotKeys.value;
  }
});

onMounted(setCommandBarData);
</script>

<!-- eslint-disable vue/attribute-hyphenation -->
<template>
  <ninja-keys
    ref="ninjakeys"
    noAutoLoadMdIcons
    hideBreadcrumbs
    :placeholder="placeholder"
    @selected="onSelected"
    @closed="onClosed"
  />
</template>

<style lang="scss">
ninja-keys {
  --ninja-accent-color: var(--w-500);
  --ninja-font-family: 'Inter';
  z-index: 9999;
}

// Wrapped with body.dark to avoid overriding the default theme
// If OS is in dark theme and app is in light mode, It will prevent showing dark theme in command bar
body.dark {
  ninja-keys {
    --ninja-overflow-background: rgba(26, 29, 30, 0.5);
    --ninja-modal-background: #151718;
    --ninja-secondary-background-color: #26292b;
    --ninja-selected-background: #26292b;
    --ninja-footer-background: #2b2f31;
    --ninja-text-color: #f8faf9;
    --ninja-icon-color: #f8faf9;
    --ninja-secondary-text-color: #c2c9c6;
  }
}
</style>
