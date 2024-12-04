<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import ConversationSortMenu from './ConversationSortMenu.vue';

defineProps({
  title: {
    type: String,
    default: '',
  },
  activeStatus: {
    type: String,
    default: 'open',
  },
  activeOrdering: {
    type: String,
    default: 'last_activity_at_desc',
  },
});

const emit = defineEmits([
  'filter',
  'update:activeStatus',
  'update:activeOrdering',
]);
</script>

<template>
  <div
    class="flex items-center justify-between gap-2 pt-4 pb-4 ltr:pl-6 rtl:pr-6 ltr:pr-5 rtl:pl-5"
  >
    <h4
      class="min-w-0 text-base font-semibold leading-5 truncate text-n-slate-12"
    >
      {{ title }}
    </h4>
    <div class="flex items-center gap-2">
      <Button
        icon="i-lucide-list-filter"
        color="slate"
        size="sm"
        variant="ghost"
        @click="emit('filter')"
      />
      <ConversationSortMenu
        :active-status="activeStatus"
        :active-ordering="activeOrdering"
        @update:active-status="emit('update:activeStatus', $event)"
        @update:active-ordering="emit('update:activeOrdering', $event)"
      />
    </div>
  </div>
</template>
