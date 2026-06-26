<script setup>
import { computed, toRef } from 'vue';

import { usePanelIaState } from 'dashboard/composables/usePanelIaState';

import Banner from 'dashboard/components/ui/Banner.vue';

const props = defineProps({
  chat: {
    type: Object,
    required: true,
  },
});

const { state, isBotHandled } = usePanelIaState(toRef(props, 'chat'));

const showBanner = computed(
  () => isBotHandled.value && state.value === 'solicita_ayuda'
);
</script>

<template>
  <Banner
    v-if="showBanner"
    color-scheme="secondary"
    class="mx-2 mt-2 shrink-0 rounded-lg !py-2"
    :banner-message="$t('CONVERSATION.PANEL_IA_HANDOFF_BANNER')"
  />
</template>
