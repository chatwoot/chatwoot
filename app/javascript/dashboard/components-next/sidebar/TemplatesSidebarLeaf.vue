<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useWhatsAppTemplateSync } from 'dashboard/composables/useWhatsAppTemplateSync';

defineProps({
  label: {
    type: String,
    required: true,
  },
  // eslint-disable-next-line vue/no-unused-properties -- passed by SidebarGroupLeaf
  active: {
    type: Boolean,
    default: false,
  },
  icon: {
    type: [String, Object],
    default: null,
  },
});

const { isSyncing, canSync, syncTemplates } = useWhatsAppTemplateSync();

const onSyncClick = event => {
  event.preventDefault();
  event.stopPropagation();
  syncTemplates();
};
</script>

<template>
  <span v-if="icon" class="size-4 grid place-content-center rounded-full">
    <Icon :icon="icon" class="size-4 inline-block" />
  </span>
  <div class="flex-1 truncate min-w-0 text-sm">{{ label }}</div>
  <button
    v-tooltip.top="$t('WHATSAPP_TEMPLATE_MGMT.SYNC_TEMPLATES')"
    type="button"
    class="flex size-6 flex-shrink-0 items-center justify-center rounded-md text-n-slate-10 hover:bg-n-alpha-2 hover:text-n-slate-12 focus-visible:bg-n-alpha-2 focus-visible:outline-none disabled:opacity-40 disabled:pointer-events-none"
    :disabled="!canSync || isSyncing"
    :aria-label="$t('WHATSAPP_TEMPLATE_MGMT.SYNC_TEMPLATES')"
    @click="onSyncClick"
  >
    <span
      class="i-lucide-refresh-cw size-4 flex-shrink-0"
      :class="{ 'animate-spin': isSyncing }"
    />
  </button>
</template>
