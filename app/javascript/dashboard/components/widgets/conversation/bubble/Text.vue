<template>
  <div
    class="message-text__wrap"
    :class="{
      'show--quoted': isQuotedContentPresent,
      'hide--quoted': !isQuotedContentPresent,
    }"
  >
    <div v-if="!isEmail" v-dompurify-html="message" class="text-content" />
    <div v-else @click="handleClickOnContent">
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
    <gallery-view
      v-if="showGalleryViewer"
      :show.sync="showGalleryViewer"
      :attachment="attachment"
      :all-attachments="availableAttachments"
      @error="onClose"
      @close="onClose"
    />
  </div>
</template>

<script>
import Letter from 'vue-letter';
import GalleryView from '../components/GalleryView.vue';

export default {
  components: { Letter, GalleryView },
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
      showGalleryViewer: false,
      attachment: {},
      availableAttachments: [],
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
      // if event target is IMG and not close in A tag
      // then open image preview
      const isImageElement = event.target.tagName === 'IMG';
      const isWrappedInLink = event.target.closest('A');

      if (isImageElement && !isWrappedInLink) {
        this.openImagePreview(event.target.src);
      }
    },
    openImagePreview(src) {
      this.showGalleryViewer = true;
      this.attachment = {
        file_type: 'image',
        data_url: src,
        message_id: Math.floor(Math.random() * 100),
      };
      this.availableAttachments = [{ ...this.attachment }];
    },
    onClose() {
      this.showGalleryViewer = false;
      this.resetAttachmentData();
    },
    resetAttachmentData() {
      this.attachment = {};
      this.availableAttachments = [];
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
