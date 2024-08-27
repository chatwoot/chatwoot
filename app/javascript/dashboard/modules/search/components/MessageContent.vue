<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import ReadMore from './ReadMore.vue';

export default {
  components: {
    ReadMore,
  },
  props: {
    author: {
      type: String,
      default: '',
    },
    content: {
      type: String,
      default: '',
    },
    searchTerm: {
      type: String,
      default: '',
    },
  },
  setup() {
    const { formatMessage, highlightContent } = useMessageFormatter();
    return {
      formatMessage,
      highlightContent,
    };
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
    this.$watch(() => {
      return this.$refs.messageContainer;
    }, this.setOverflow);

    this.$nextTick(this.setOverflow);
  },
  methods: {
    setOverflow() {
      const wrap = this.$refs.messageContainer;
      if (wrap) {
        const message = wrap.querySelector('.message-content');
        this.isOverflowing = message.offsetHeight > 150;
      }
    },
    escapeHtml(html) {
      var text = document.createTextNode(html);
      var p = document.createElement('p');
      p.appendChild(text);
      return p.innerText;
    },
    prepareContent(content = '') {
      const escapedText = this.escapeHtml(content);
      return this.highlightContent(
        escapedText,
        this.searchTerm,
        'searchkey--highlight'
      );
    },
  },
};
</script>

<template>
  <blockquote
    ref="messageContainer"
    class="message border-l-2 border-slate-100 dark:border-slate-700"
  >
    <p class="header">
      <strong class="text-slate-700 dark:text-slate-100">
        {{ author }}
      </strong>
      {{ $t('SEARCH.WROTE') }}
    </p>
    <ReadMore :shrink="isOverflowing" @expand="isOverflowing = false">
      <div v-dompurify-html="prepareContent(content)" class="message-content" />
    </ReadMore>
  </blockquote>
</template>

<style scoped lang="scss">
.message {
  @apply py-0 px-2 mt-2;
}
.message-content::v-deep p,
.message-content::v-deep li::marker {
  @apply text-slate-700 dark:text-slate-100 mb-1;
}

.header {
  @apply text-slate-500 dark:text-slate-300 mb-1;
}

.message-content {
  @apply break-words text-slate-600 dark:text-slate-200;
}

.message-content::v-deep .searchkey--highlight {
  @apply text-woot-600 dark:text-woot-500 text-sm font-semibold;
}
</style>
