<script setup>
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  scheduler: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['delete']);
const { t } = useI18n();

const messageTypeLabel = type => {
  return t(`SCHEDULER.MESSAGE_TYPES.${type}`) || type;
};

const statusColor = status => {
  return status === 'active'
    ? 'bg-n-teal-3 text-n-teal-11'
    : 'bg-n-slate-3 text-n-slate-11';
};
</script>

<template>
  <div
    class="flex flex-col gap-3 p-4 border rounded-xl border-n-weak bg-n-solid-2 hover:bg-n-solid-3 transition-colors"
  >
    <div class="flex items-start justify-between gap-2">
      <div class="flex flex-col gap-1 min-w-0">
        <h3 class="text-sm font-semibold text-n-slate-12 truncate">
          {{ scheduler.title }}
        </h3>
        <p
          v-if="scheduler.description"
          class="text-xs text-n-slate-11 line-clamp-2"
        >
          {{ scheduler.description }}
        </p>
      </div>
      <Button
        icon="i-lucide-trash-2"
        variant="ghost"
        color="ruby"
        size="xs"
        @click="emit('delete', scheduler)"
      />
    </div>
    <div class="flex items-center gap-2 flex-wrap">
      <span
        class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium bg-n-blue-3 text-n-blue-11"
      >
        {{ messageTypeLabel(scheduler.message_type) }}
      </span>
      <span
        class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium"
        :class="statusColor(scheduler.status)"
      >
        {{ t(`SCHEDULER.STATUS.${scheduler.status}`) }}
      </span>
      <span
        v-if="scheduler.inbox"
        class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium bg-n-slate-3 text-n-slate-11"
      >
        {{ scheduler.inbox.name }}
      </span>
    </div>
  </div>
</template>
