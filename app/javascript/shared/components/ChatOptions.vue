<template>
  <div class="chat-bubble agent" :class="$dm('bg-white', 'dark:bg-slate-700')">
    <div
      v-dompurify-html="formattedMessage"
      class="message-content"
      :class="$dm('text-black-900', 'dark:text-slate-50')"
    />
  </div>
</template>

<script>
import darkModeMixin from 'widget/mixins/darkModeMixin.js';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';

export default {
  mixins: [darkModeMixin, messageFormatterMixin],
  props: {
    message: {
      type: String,
      default: '',
    },
  },
  computed: {
    formattedMessage() {
      const messageWithLineBreak = this.message.replace(/\\n/g,'\n')
      return this.formatMessage(messageWithLineBreak)
    }
  }
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.options-message {
  max-width: 17rem;
  padding: $space-small $space-normal;
  border-radius: $space-small;
  overflow: hidden;

  .title {
    font-size: $font-size-default;
    font-weight: $font-weight-normal;
    margin-top: $space-smaller;
    margin-bottom: $space-smaller;
    line-height: 1.5;
  }
}
</style>
