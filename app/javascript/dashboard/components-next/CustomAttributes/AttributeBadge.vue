<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  type: {
    type: String,
    default: 'resolution',
    validator: value => ['pre-chat', 'resolution'].includes(value),
  },
});

const { t } = useI18n();

const attributeConfig = {
  'pre-chat': {
    colorClass: 'text-on-tertiary-container',
    icon: 'i-lucide-message-circle',
    labelKey: 'ATTRIBUTES_MGMT.BADGES.PRE_CHAT',
  },
  resolution: {
    colorClass: 'text-secondary',
    icon: 'i-lucide-circle-check-big',
    labelKey: 'ATTRIBUTES_MGMT.BADGES.RESOLUTION',
  },
};
const config = computed(
  () => attributeConfig[props.type] || attributeConfig.resolution
);
</script>

<template>
  <div
    class="flex items-center justify-center gap-1 rounded-md border border-outline-variant/25 bg-surface-container-high/50 px-2 py-1"
  >
    <Icon :icon="config.icon" class="size-4" :class="config.colorClass" />
    <span class="text-xs" :class="config.colorClass">{{
      t(config.labelKey)
    }}</span>
  </div>
</template>
