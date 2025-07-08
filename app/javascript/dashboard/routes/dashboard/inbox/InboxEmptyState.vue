<script>
import { mapGetters } from 'vuex';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

export default {
  components: {
    Spinner,
  },
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
    <div v-if="uiFlags.isFetching" class="flex justify-center my-4">
      <Spinner class="text-n-brand" />
    </div>
    <div v-else class="flex flex-col items-center gap-2">
      <fluent-icon icon="mail-inbox" size="40" class="text-n-slate-11" />
      <span class="text-sm font-medium text-n-slate-11">
        {{ emptyMessage }}
      </span>
    </div>
  </div>
</template>
