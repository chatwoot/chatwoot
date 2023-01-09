<template>
  <dyte-video-call
    v-if="contentAttributes.type === 'dyte'"
    :message-id="messageId"
    :meeting-data="contentAttributes.data"
  />
</template>
<script>
import DyteVideoCall from './integrations/Dyte.vue';
export default {
  components: { DyteVideoCall },
  props: {
    messageId: {
      type: Number,
      required: true,
    },
    contentAttributes: {
      type: Object,
      default: () => ({}),
    },
  },
};
</script>
