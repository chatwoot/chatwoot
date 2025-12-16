<script setup>
import { computed } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useMapGetter } from 'dashboard/composables/store';
import { useWindowSize } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import wootConstants from 'dashboard/constants/globals';
import ConversationSummaryPanel from './ConversationSummaryPanel.vue';

const { width: windowWidth } = useWindowSize();
const { uiSettings, updateUISettings } = useUISettings();
const currentChat = useMapGetter('getSelectedChat');

const isSmallScreen = computed(
  () => windowWidth.value < wootConstants.SMALL_SCREEN_BREAKPOINT
);

const isConversationSummaryOpen = computed(
  () => uiSettings.value.is_conversation_summary_open
);

const shouldShowPanel = computed(() => {
  return isConversationSummaryOpen.value && currentChat.value.id;
});

const closePanel = () => {
  if (isSmallScreen.value && isConversationSummaryOpen.value) {
    updateUISettings({
      is_conversation_summary_open: false,
    });
  }
};
</script>

<template>
  <div
    v-if="shouldShowPanel"
    v-on-click-outside="() => closePanel()"
    class="bg-n-background h-full overflow-hidden flex flex-col fixed top-0 ltr:right-0 rtl:left-0 z-40 w-full max-w-sm transition-transform duration-300 ease-in-out md:static md:w-[320px] md:min-w-[320px] ltr:border-l rtl:border-r border-n-weak 2xl:min-w-[360px] 2xl:w-[360px] shadow-lg md:shadow-none"
    :class="[
      {
        'md:flex': shouldShowPanel,
        'md:hidden': !shouldShowPanel,
      },
    ]"
  >
    <ConversationSummaryPanel :conversation-id="currentChat.id" />
  </div>
  <template v-else />
</template>
