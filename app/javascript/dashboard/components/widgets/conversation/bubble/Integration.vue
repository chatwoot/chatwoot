<script>
import DyteVideoCall from './integrations/Dyte.vue';
import inboxMixin from 'shared/mixins/inboxMixin';

export default {
  components: { DyteVideoCall },
  mixins: [inboxMixin],
  props: {
    messageId: {
      type: [String, Number],
      default: 0,
    },
    contentAttributes: {
      type: Object,
      default: () => ({}),
    },
    inboxId: {
      type: [String, Number],
      default: 0,
    },
  },
  computed: {
    showDyteIntegration() {
      const isEnabledOnTheInbox = this.isAPIInbox || this.isAWebWidgetInbox;
      return isEnabledOnTheInbox && this.contentAttributes.type === 'dyte';
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },
  },
  mounted() {
    // Log integration type for debugging if needed
    if (process.env.NODE_ENV !== 'production') {
      console.log('Integration component mounted with type:', this.contentAttributes.type);
    }
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <DyteVideoCall
    v-if="showDyteIntegration"
    :message-id="messageId"
    :meeting-data="contentAttributes.data"
  />
  <div v-else class="integration-not-supported">
    {{ contentAttributes.type || 'Unknown' }} integration
  </div>
</template>

<style lang="scss" scoped>
.integration-not-supported {
  @apply text-xs text-slate-500 dark:text-slate-400 p-2 bg-slate-50 dark:bg-slate-700 rounded;
}
</style>
