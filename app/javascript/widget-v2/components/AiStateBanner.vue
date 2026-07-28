<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useConfigStore } from 'widget-v2/stores/config';

const props = defineProps({
  aiState: { type: String, required: true },
  assignee: { type: Object, default: null },
});

const { t } = useI18n();
const configStore = useConfigStore();

const label = computed(() => {
  if (props.aiState === 'ai') {
    return t('AI_STATE.AI', {
      name: configStore.aiAgent?.name || t('AI_STATE.AI_DEFAULT_NAME'),
    });
  }
  if (props.aiState === 'human') {
    return t('AI_STATE.HUMAN', {
      name: props.assignee?.name || t('AI_STATE.HUMAN_DEFAULT_NAME'),
    });
  }
  return t('CONVERSATION.RESOLVED_NOTICE');
});
</script>

<template>
  <div class="flex justify-center pt-3">
    <span
      class="inline-flex items-center gap-1.5 px-3 h-6 text-xs font-medium rounded-full"
      :class="
        aiState === 'ai'
          ? 'bg-cw-primary-soft text-cw-primary'
          : 'bg-cw-muted text-cw-text-muted'
      "
    >
      <span
        v-if="aiState === 'ai'"
        class="w-1.5 h-1.5 rounded-full bg-cw-primary animate-loader-pulse"
      />
      <span v-else-if="aiState === 'human'" class="i-ph-user" />
      <span v-else class="i-ph-check" />
      {{ label }}
    </span>
  </div>
</template>
