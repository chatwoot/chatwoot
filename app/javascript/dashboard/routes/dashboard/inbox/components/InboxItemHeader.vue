<script setup>
import PaginationButton from './PaginationButton.vue';

const props = defineProps({
  totalLength: {
    type: Number,
    default: 0,
  },
  currentIndex: {
    type: Number,
    default: 0,
  },
});

const onSnooze = () => {
  // TODO: Implement snooze
};

const onDelete = () => {
  // TODO: Implement delete
};
</script>

<template>
  <div
    class="flex gap-2 py-2 pl-4 pr-2 justify-between items-center w-full border-b border-slate-200 dark:border-slate-500"
  >
    <pagination-button
      :total-length="props.totalLength"
      :current-index="props.currentIndex"
    />
    <div class="flex items-center gap-2">
      <woot-button
        variant="hollow"
        size="small"
        color-scheme="secondary"
        icon="snooze"
        @click="onSnooze"
      >
        Snooze
      </woot-button>
      <woot-button
        icon="delete"
        size="small"
        color-scheme="secondary"
        variant="hollow"
        @click="onDelete"
      >
        Delete notification
      </woot-button>
    </div>
  </div>
</template>
