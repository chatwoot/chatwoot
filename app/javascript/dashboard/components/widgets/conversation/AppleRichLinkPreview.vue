<script>
import {
  createRichLinkPreview,
  isAppleMessagesConversation,
} from 'dashboard/helper/appleMessagesRichLink';

export default {
  name: 'AppleRichLinkPreview',
  props: {
    url: {
      type: String,
      required: true,
    },
    conversation: {
      type: Object,
      required: true,
    },
    originalMessage: {
      type: String,
      required: true,
    },
  },
  emits: ['send-as-text', 'send-as-rich-link', 'dismiss'],
  data() {
    return {
      isLoading: false,
      previewData: null,
      showPreview: false,
      mainImageError: false,
      faviconError: false,
    };
  },
  watch: {
    url: {
      handler(newUrl) {
        if (newUrl && isAppleMessagesConversation(this.conversation)) {
          this.loadPreview();
        } else {
          this.showPreview = false;
        }
      },
      immediate: true,
    },
  },
  methods: {
    async loadPreview() {
      if (!this.url) return;

      this.isLoading = true;
      this.showPreview = true;
      this.previewData = null;

      try {
        const result = await createRichLinkPreview(this.url);

        if (result.success) {
          this.previewData = result.richLinkData;
        } else {
          console.error('Rich Link preview failed:', result.error);
        }
      } catch (error) {
        console.error('Rich Link preview error:', error);
      } finally {
        this.isLoading = false;
      }
    },

    dismissPreview() {
      this.showPreview = false;
      this.$emit('dismiss');
    },

    sendAsText() {
      this.$emit('send-as-text', this.originalMessage);
      this.dismissPreview();
    },

    sendAsRichLink() {
      if (this.previewData) {
        this.$emit('send-as-rich-link', {
          url: this.url,
          richLinkData: this.previewData,
          originalMessage: this.originalMessage,
        });
        this.dismissPreview();
      }
    },

    onMainImageError() {
      this.mainImageError = true;
    },

    onFaviconError() {
      this.faviconError = true;
    },
  },
};
</script>

<template>
  <div v-if="showPreview" class="apple-rich-link-preview">
    <div class="preview-header">
      <fluent-icon icon="link" size="16" class="text-slate-500" />
      <span class="preview-title">{{
        $t('CONVERSATION.APPLE_MESSAGES.RICH_LINK_PREVIEW')
      }}</span>
      <button
        v-tooltip="$t('CONVERSATION.APPLE_MESSAGES.DISMISS_PREVIEW')"
        class="dismiss-button"
        @click="dismissPreview"
      >
        <fluent-icon icon="dismiss" size="14" />
      </button>
    </div>

    <div v-if="isLoading" class="preview-loading">
      <div class="loading-spinner" />
      <span>{{ $t('CONVERSATION.APPLE_MESSAGES.LOADING_PREVIEW') }}</span>
    </div>

    <div v-else-if="previewData" class="preview-content">
      <div class="preview-image">
        <!-- Try main image first -->
        <img
          v-if="previewData.image_url && !mainImageError"
          :src="previewData.image_url"
          :alt="previewData.title"
          @error="onMainImageError"
        />
        <!-- Fallback to favicon if main image fails or doesn't exist -->
        <img
          v-else-if="previewData.favicon_url && !faviconError"
          :src="previewData.favicon_url"
          :alt="previewData.title"
          class="favicon-fallback"
          @error="onFaviconError"
        />
        <!-- Final fallback - website icon -->
        <div v-else class="fallback-icon">
          <svg
            class="w-6 h-6 text-slate-400"
            fill="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              d="M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z"
            />
          </svg>
        </div>
      </div>
      <div class="preview-text">
        <div class="preview-url">{{ previewData.url }}</div>
        <div v-if="previewData.title" class="preview-title-text">
          {{ previewData.title }}
        </div>
        <div v-if="previewData.description" class="preview-description">
          {{ previewData.description }}
        </div>
        <div v-if="previewData.site_name" class="preview-site">
          {{ previewData.site_name }}
        </div>
      </div>
    </div>

    <div v-else class="preview-error">
      <fluent-icon icon="warning" size="16" class="text-red-500" />
      <span>{{ $t('CONVERSATION.APPLE_MESSAGES.PREVIEW_ERROR') }}</span>
    </div>

    <div class="preview-actions">
      <button class="action-button secondary" @click="sendAsText">
        {{ $t('CONVERSATION.APPLE_MESSAGES.SEND_AS_TEXT') }}
      </button>
      <button
        class="action-button primary"
        :disabled="!previewData"
        @click="sendAsRichLink"
      >
        {{ $t('CONVERSATION.APPLE_MESSAGES.SEND_AS_RICH_LINK') }}
      </button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.apple-rich-link-preview {
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 12px;
  background: var(--color-background);

  .preview-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 8px;

    .preview-title {
      font-size: 14px;
      font-weight: 500;
      color: var(--color-body);
      flex: 1;
      margin-left: 8px;
    }

    .dismiss-button {
      padding: 4px;
      border-radius: 4px;
      color: var(--s-500);
      cursor: pointer;
      background: none;
      border: none;

      &:hover {
        background: var(--color-background-light);
        color: var(--color-body);
      }
    }
  }

  .preview-loading {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 16px 0;
    font-size: 14px;
    color: var(--s-500);

    .loading-spinner {
      width: 16px;
      height: 16px;
      border: 2px solid var(--w-500);
      border-top-color: transparent;
      border-radius: 50%;
      animation: spin 1s linear infinite;
    }
  }

  .preview-content {
    display: flex;
    gap: 12px;
    margin-bottom: 12px;

    .preview-image {
      flex-shrink: 0;
      width: 64px;
      height: 64px;
      border-radius: 4px;
      overflow: hidden;
      background: var(--color-background-light);
      display: flex;
      align-items: center;
      justify-content: center;

      img {
        width: 100%;
        height: 100%;
        object-fit: cover;

        &.favicon-fallback {
          width: 32px;
          height: 32px;
          object-fit: contain;
        }
      }

      .fallback-icon {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 100%;
        height: 100%;
      }
    }

    .preview-text {
      flex: 1;
      min-width: 0;

      .preview-url {
        font-size: 12px;
        color: var(--w-500);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        margin-bottom: 4px;
      }

      .preview-title-text {
        font-size: 14px;
        font-weight: 500;
        color: var(--color-body);
        line-height: 1.3;
        margin-bottom: 4px;
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
      }

      .preview-description {
        font-size: 12px;
        color: var(--s-500);
        line-height: 1.3;
        margin-bottom: 4px;
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
      }

      .preview-site {
        font-size: 11px;
        color: var(--s-400);
        text-transform: uppercase;
        letter-spacing: 0.5px;
      }
    }
  }

  .preview-error {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 0;
    font-size: 14px;
    color: var(--r-500);
  }

  .preview-actions {
    display: flex;
    gap: 8px;
    justify-content: flex-end;

    .action-button {
      padding: 6px 12px;
      font-size: 14px;
      border-radius: 6px;
      font-weight: 500;
      cursor: pointer;
      border: none;
      transition: all 0.2s ease;

      &.secondary {
        background: var(--color-background-light);
        color: var(--color-body);

        &:hover {
          background: var(--s-75);
        }
      }

      &.primary {
        background: var(--w-500);
        color: white;

        &:hover {
          background: var(--w-600);
        }

        &:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }
      }
    }
  }
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
