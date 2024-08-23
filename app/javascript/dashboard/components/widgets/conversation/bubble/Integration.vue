<script>
import DyteVideoCall from './integrations/Dyte.vue';
import { useInbox } from 'shared/composables/useInbox';

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
  setup(props) {
    const { isAPIInbox, isAWebWidgetInbox } = useInbox({
      inboxId: props.inboxId,
    });
    return {
      isAPIInbox,
      isAWebWidgetInbox,
    };
  },
  computed: {
    showDyteIntegration() {
      const isEnabledOnTheInbox = this.isAPIInbox || this.isAWebWidgetInbox;
      return isEnabledOnTheInbox && this.contentAttributes.type === 'dyte';
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
