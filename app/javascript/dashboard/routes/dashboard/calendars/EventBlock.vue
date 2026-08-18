<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  event: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['select']);
const { t } = useI18n();

const isCompact = event => Number(event.height) < 12;
</script>

<template>
  <button
    type="button"
    class="absolute left-1 right-1 z-[1] overflow-hidden rounded-md px-1 py-0.5 text-left"
    :class="
      event.deleted
        ? 'bg-n-ruby-3/80 text-n-ruby-11 line-through hover:bg-n-ruby-4'
        : 'bg-n-blue-9 text-white hover:bg-n-blue-10'
    "
    :style="{ top: `${event.top}%`, height: `${event.height}%` }"
    @click.stop="emit('select', event)"
  >
    <span
      v-if="isCompact(event)"
      class="flex items-center gap-1 min-w-0 text-[11px] leading-tight"
    >
      <span class="shrink-0 font-medium">
        {{
          event.deleted ? t('SIDEBAR.CALENDAR_PAGE.DELETED') : event.timeLabel
        }}
      </span>
      <span class="truncate">{{ event.summary }}</span>
    </span>
    <span v-else class="flex items-start justify-between gap-1 min-w-0">
      <span class="min-w-0">
        <span
          v-if="event.deleted"
          class="block text-[10px] font-medium leading-tight"
        >
          {{ t('SIDEBAR.CALENDAR_PAGE.DELETED') }}
        </span>
        <span class="block text-[11px] font-medium leading-tight truncate">
          {{ event.summary }}
        </span>
        <span
          v-if="event.deleted_by?.name && event.height >= 18"
          class="block text-[10px] leading-tight opacity-80 truncate"
        >
          {{ event.deleted_by.name }}
        </span>
        <span
          v-else-if="event.created_by?.name && event.height >= 18"
          class="block text-[10px] leading-tight opacity-80 truncate"
        >
          {{ event.created_by.name }}
        </span>
      </span>
      <span class="shrink-0 text-[10px] leading-tight opacity-90">
        {{ event.timeLabel }}
      </span>
    </span>
  </button>
</template>
