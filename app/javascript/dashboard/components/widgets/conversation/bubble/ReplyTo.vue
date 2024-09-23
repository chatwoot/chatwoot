<template>
  <div
    class="block px-2 py-1.5 rounded-sm min-w-[10rem] mb-2 bg-woot-50 text-woot-300 text-xs hover:cursor-pointer"
    :class="{
      '-mx-2': !parentHasAttachments,
    }"
    @click="$emit('scroll-to')"
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
import { MESSAGE_TYPE } from 'shared/constants/messages';

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
    messageType: {
      type: Number,
      required: true,
    },
    parentHasAttachments: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return { MESSAGE_TYPE };
  },
};
</script>
