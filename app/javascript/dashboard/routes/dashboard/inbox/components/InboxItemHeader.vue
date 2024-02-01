<script>
import PaginationButton from './PaginationButton.vue';

export default {
  components: {
    PaginationButton,
  },
  props: {
    totalLength: {
      type: Number,
      default: 0,
    },
    currentIndex: {
      type: Number,
      default: 0,
    },
  },
  methods: {
    onSnooze() {},
    onDelete() {},
  },
};
</script>

<template>
  <div
    class="flex gap-2 py-2 pl-4 h-14 pr-2 justify-between items-center w-full border-b border-slate-50 dark:border-slate-800/50"
  >
    <pagination-button
      :total-length="totalLength"
      :current-index="currentIndex"
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
