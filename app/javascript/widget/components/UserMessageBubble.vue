<template>
  <div
    v-dompurify-html="formatMessage(message, false)"
    class="chat-bubble user"
    :style="{ background: widgetColor, color: textColor }"
  />
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import { getContrastingTextColor } from '@chatwoot/utils';

export default {
  name: 'UserMessageBubble',
  mixins: [messageFormatterMixin],
  props: {
    message: {
      type: String,
      default: '',
    },
    status: {
      type: String,
      default: '',
    },
    widgetColor: {
      type: String,
      default: '',
    },
  },
  computed: {
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.chat-bubble.user::v-deep {
  p code {
    background-color: var(--w-600);
    color: var(--white);
  }

  pre {
    background-color: var(--w-800);
    border-color: var(--w-700);
    color: var(--white);

    code {
      background-color: transparent;
      color: var(--white);
    }
  }

  blockquote {
    border-left: $space-micro solid var(--w-400);
    background: var(--s-25);
    border-color: var(--s-200);

    p {
      color: var(--s-800);
    }
  }
}
</style>
