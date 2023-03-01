<template>
  <blockquote ref="messageContainer" class="message">
    <p class="header">
      <strong class="author">
        {{ author }}
      </strong>
      {{ $t('SEARCH.WROTE') }}
    </p>
    <read-more :shrink="isOverflowing" @expand="isOverflowing = false">
      <div v-dompurify-html="messageContent" class="message-content" />
    </read-more>
  </blockquote>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import ReadMore from './ReadMore.vue';

export default {
  components: {
    ReadMore,
  },
  mixins: [messageFormatterMixin],
  props: {
    author: {
      type: String,
      default: '',
    },
    content: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      isOverflowing: false,
    };
  },
  computed: {
    messageContent() {
      return this.formatMessage(this.content);
    },
  },
  mounted() {
    this.$nextTick(() => {
      const wrap = this.$refs.messageContainer;
      const message = wrap.querySelector('.message-content');
      this.isOverflowing = message.offsetHeight > 150;
    });
  },
};
</script>

<style scoped lang="scss">
.message {
  border-color: var(--s-100);
  border-width: var(--space-micro);
  padding: 0 var(--space-small);
  margin-top: var(--space-small);
}
.message-content::v-deep p,
.message-content::v-deep li::marker {
  color: var(--s-700);
  margin-bottom: var(--space-smaller);
}
.author {
  color: var(--s-700);
}
.header {
  color: var(--s-500);
  margin-bottom: var(--space-smaller);
}
</style>
