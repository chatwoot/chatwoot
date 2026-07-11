<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { statusConfig, priorityConfig } from 'dashboard/helper/internalTaskUi';

const props = defineProps({
  status: { type: String, required: true },
  priority: { type: String, default: '' },
  compact: { type: Boolean, default: false },
});

const { t } = useI18n();

const config = computed(() => statusConfig(props.status));
const priority = computed(() =>
  props.priority ? priorityConfig(props.priority) : null
);
</script>

<template>
  <div class="flex flex-wrap items-center gap-1">
    <span
      class="inline-flex items-center rounded-md font-medium"
      :class="[
        config.badge,
        compact ? 'px-1.5 py-0.5 text-xxs' : 'px-2 py-0.5 text-xs',
      ]"
    >
      {{ t(`INTERNAL_TASKS.STATUS.${status.toUpperCase()}`) }}
    </span>
    <span
      v-if="priority && props.priority !== 'normal'"
      class="inline-flex rounded-md font-medium uppercase tracking-wide"
      :class="[
        priority.badge,
        compact ? 'px-1.5 py-0.5 text-xxs' : 'px-2 py-0.5 text-xs',
      ]"
    >
      {{ t(`INTERNAL_TASKS.PRIORITY.${props.priority.toUpperCase()}`) }}
    </span>
  </div>
</template>
