<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { getContrastingTextColor } from '@chatwoot/utils';

export default {
  name: 'UserMessageBubble',
  props: {
    message: {
      type: String,
      default: '',
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
};
</script>

<template>
  <div
    v-dompurify-html="formatMessage(message, false)"
    class="chat-bubble user"
    :style="{ background: widgetColor, color: textColor }"
  />
</template>

<style lang="scss" scoped>
.chat-bubble.user::v-deep {
  p code {
    @apply bg-s-subtle dark:bg-s-subtle text-white;
  }

  pre {
    @apply text-white bg-s-subtle dark:bg-s-subtle;

    code {
      @apply bg-transparent text-white;
    }
  }

  blockquote {
    @apply bg-transparent border-s-border ltr:border-l-2 rtl:border-r-2 border-solid;

    p {
      @apply text-s-disabled dark:text-s-primary/90;
    }
  }
}
</style>
