<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'next/icon/Icon.vue';
import { useMessageSource } from 'dashboard/composables/useMessageSource';

const props = defineProps({
  contentAttributes: { type: Object, default: () => ({}) },
  iconClass: { type: String, default: 'size-4 text-n-slate-11' },
});

const { t } = useI18n();
const { source, icon, i18nKey, hasSource } = useMessageSource(
  computed(() => props.contentAttributes)
);

const tooltip = computed(() => {
  if (!hasSource.value) return '';

  const { type, id, name } = source.value;
  if (name && i18nKey.value) {
    return t(i18nKey.value, { name });
  }

  return t('MESSAGE_SOURCE.FALLBACK', { type, id });
});
</script>

<template>
  <Icon
    v-if="hasSource && icon"
    v-tooltip.top="tooltip"
    :icon="icon"
    :class="iconClass"
    data-testid="message-source-indicator"
  />
</template>
