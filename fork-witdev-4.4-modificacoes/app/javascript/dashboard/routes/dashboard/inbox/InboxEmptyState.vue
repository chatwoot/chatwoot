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

<template>
  <div
    class="items-center justify-center hidden w-full h-full text-center bg-n-background lg:flex"
  >
    <span v-if="uiFlags.isFetching" class="my-4 spinner" />
    <div v-else class="flex flex-col items-center gap-2">
      <fluent-icon
        icon="mail-inbox"
        size="40"
        class="text-slate-600 dark:text-slate-400"
      />
      <span class="text-sm font-medium text-slate-500 dark:text-slate-300">
        {{ emptyMessage }}
      </span>
    </div>
  </div>
</template>
