<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Label from 'dashboard/components-next/label/Label.vue';

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
    colorClass: 'text-n-blue-11',
    icon: 'i-lucide-message-circle',
    labelKey: 'ATTRIBUTES_MGMT.BADGES.PRE_CHAT',
    color: 'slate',
  },
  resolution: {
    colorClass: 'text-n-teal-11',
    icon: 'i-lucide-circle-check-big',
    labelKey: 'ATTRIBUTES_MGMT.BADGES.RESOLUTION',
    color: 'slate',
  },
};
const config = computed(
  () => attributeConfig[props.type] || attributeConfig.resolution
);
</script>

<template>
  <Label :label="t(config.labelKey)" :color="config.color" compact>
    <template #icon>
      <Icon :icon="config.icon" class="size-3.5 text-n-slate-12" />
    </template>
  </Label>
</template>
