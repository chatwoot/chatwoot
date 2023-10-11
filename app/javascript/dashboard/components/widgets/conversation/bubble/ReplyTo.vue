<template>
  <div
    class="px-2 py-1.5 -mx-2 rounded-md bg-woot-600 text-woot-50 min-w-[15rem] mb-2"
  >
    <message-preview
      :message="message"
      :show-message-type="false"
      :default-empty-message="$t('CONVERSATION.REPLY_MESSAGE_NOT_FOUND')"
    />
  </div>
</template>

<script>
import MessagePreview from 'dashboard/components/widgets/conversation/MessagePreview.vue';

export default {
  name: 'ReplyTo',
  components: {
    MessagePreview,
  },
  props: {
    message: {
      type: Object,
      required: true,
    },
  },
};
</script>
