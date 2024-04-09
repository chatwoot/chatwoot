<template>
  <div
    class="text-center bg-slate-25 dark:bg-slate-800 justify-center w-full h-full hidden md:flex items-center"
  >
    <span v-if="uiFlags.isFetching" class="spinner my-4" />
    <div v-else class="flex flex-col items-center gap-2">
      <fluent-icon
        icon="mail-inbox"
        size="40"
        class="text-slate-600 dark:text-slate-400"
      />
      <span class="text-slate-500 text-sm font-medium dark:text-slate-300">
        {{ emptyMessage }}
      </span>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
export default {
  props: {
    emptyStateMessage: {
      type: String,
      default: '',
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'notifications/getUIFlags',
    }),
    emptyMessage() {
      if (this.emptyStateMessage) {
        return this.emptyStateMessage;
      }
      return this.$t('INBOX.LIST.NOTE');
    },
  },
};
</script>
