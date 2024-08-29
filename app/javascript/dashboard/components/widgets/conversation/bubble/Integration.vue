<script>
import DyteVideoCall from './integrations/Dyte.vue';
import { isAPIInbox, isAWebWidgetInbox } from 'shared/helpers/inboxHelper';

export default {
  components: { DyteVideoCall },
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
      const isEnabledOnTheInbox =
        isAPIInbox(this.inbox) || isAWebWidgetInbox(this.inbox);
      return isEnabledOnTheInbox && this.contentAttributes.type === 'dyte';
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },
  },
};
</script>

<template>
  <DyteVideoCall
    v-if="showDyteIntegration"
    :message-id="messageId"
    :meeting-data="contentAttributes.data"
  />
</template>
