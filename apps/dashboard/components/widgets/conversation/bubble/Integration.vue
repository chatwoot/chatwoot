<template>
  <dyte-video-call
    v-if="showDyteIntegration"
    :message-id="messageId"
    :meeting-data="contentAttributes.data"
  />
</template>
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
};
</script>
