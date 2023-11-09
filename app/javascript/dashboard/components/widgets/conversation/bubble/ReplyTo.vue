<template>
  <div
    class="px-2 py-1.5 -mx-2 rounded-sm min-w-[15rem] mb-2"
    :class="{
      'bg-slate-100 dark:bg-slate-600 dark:text-slate-50':
        messageType === MESSAGE_TYPE.INCOMING,
      'bg-woot-600 text-woot-50': messageType === MESSAGE_TYPE.OUTGOING,
    }"
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
  },
  data() {
    return { MESSAGE_TYPE };
  },
};
</script>
