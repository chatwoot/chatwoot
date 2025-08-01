<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { getContrastingTextColor } from '@chatwoot/utils';
import { event } from 'vue-gtag';

export default {
  name: 'UserMessageBubble',
  props: {
    message: {
      type: String,
      default: '',
    },
    messageId: {
      type: Number,
      required: true,
    },
    widgetColor: {
      type: String,
      default: '',
    },
  },
  setup() {
    const { formatMessage } = useMessageFormatter();
    return {
      formatMessage,
    };
  },
  computed: {
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
  },
  methods: {
    handleLinkClick(e) {
      if (e.target.tagName === 'A') {
        const payload = {
          message_id: this.messageId,
          link_url: e.target.href,
        };
        // TODO: remove console.log after verification
        console.log('conversation_link_clicked', payload);
        event('conversation_link_clicked', payload);
      }
    },
  },
};
</script>

<template>
  <div
    v-dompurify-html="formatMessage(message, false)"
    class="chat-bubble user"
    :style="{ background: widgetColor, color: textColor }"
    @click="handleLinkClick"
  />
</template>

<style lang="scss" scoped>
.chat-bubble.user::v-deep {
  p code {
    @apply bg-n-alpha-2 dark:bg-n-alpha-1 text-white;
  }

  pre {
    @apply text-white bg-n-alpha-2 dark:bg-n-alpha-1;

    code {
      @apply bg-transparent text-white;
    }
  }

  blockquote {
    @apply bg-transparent border-n-slate-7 ltr:border-l-2 rtl:border-r-2 border-solid;

    p {
      @apply text-n-slate-5 dark:text-n-slate-12/90;
    }
  }
}
</style>
