<template>
  <div
    class="message-text__wrap"
    :class="{
      'show--quoted': isQuotedContentPresent,
      'hide--quoted': !isQuotedContentPresent,
    }"
  >
    <div v-if="!isEmail" v-dompurify-html="message" class="text-content" />
    <div v-else @click="handleClickOnContent($event)">
      <letter
        class="text-content bg-white dark:bg-white text-slate-900 dark:text-slate-900 p-2 rounded-[4px]"
        :html="message"
      />
    </div>
    <button
      v-if="showQuoteToggle"
      class="text-slate-300 dark:text-slate-300 cursor-pointer text-xs py-1"
      @click="toggleQuotedContent"
    >
      <span v-if="showQuotedContent" class="flex items-center gap-0.5">
        <fluent-icon icon="chevron-up" size="16" />
        {{ $t('CHAT_LIST.HIDE_QUOTED_TEXT') }}
      </span>
      <span v-else class="flex items-center gap-0.5">
        <fluent-icon icon="chevron-down" size="16" />
        {{ $t('CHAT_LIST.SHOW_QUOTED_TEXT') }}
      </span>
    </button>
    <woot-modal
      full-width
      :show.sync="show"
      :show-close-button="true"
      :on-close="onClose"
    >
      <img
        v-on-clickaway="onClose"
        :src="imageUrl"
        class="modal-image skip-context-menu my-0 mx-auto max-w-[90%] max-h-[90%]"
      />
    </woot-modal>
  </div>
</template>

<script>
import Letter from 'vue-letter';
import { mixin as clickaway } from 'vue-clickaway';

export default {
  components: { Letter },
  mixins: [clickaway],
  props: {
    message: {
      type: String,
      default: '',
    },
    isEmail: {
      type: Boolean,
      default: true,
    },
    displayQuotedButton: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showQuotedContent: false,
      show: false,
      imageUrl: '',
    };
  },
  computed: {
    isQuotedContentPresent() {
      if (!this.isEmail) {
        return this.message.includes('<blockquote');
      }
      return this.showQuotedContent;
    },
    showQuoteToggle() {
      if (!this.isEmail) {
        return false;
      }
      return this.displayQuotedButton;
    },
  },
  methods: {
    toggleQuotedContent() {
      this.showQuotedContent = !this.showQuotedContent;
    },
    handleClickOnContent(event) {
      // if event target is IMG and not wrapped with A tag
      // then open image preview
      if (
        event.target.tagName === 'IMG' &&
        event.target.parentElement.tagName !== 'A'
      ) {
        this.openImagePreview(event.target.src);
      }
    },
    openImagePreview(src) {
      this.imageUrl = src;
      this.show = true;
    },
    onClose() {
      this.show = false;
      this.imageUrl = '';
    },
  },
};
</script>
<style lang="scss">
.text-content {
  overflow: auto;

  ul,
  ol {
    padding-left: var(--space-two);
  }
  table {
    margin: 0;
    border: 0;

    td {
      margin: 0;
      border: 0;
    }

    tr {
      border-bottom: 0 !important;
    }
  }

  h1,
  h2,
  h3,
  h4,
  h5,
  h6 {
    font-size: var(--font-size-normal);
  }
}

.show--quoted {
  blockquote {
    @apply block;
  }
}

.hide--quoted {
  blockquote {
    @apply hidden;
  }
}
</style>
