<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { getContrastingTextColor } from '@chatwoot/utils';

export default {
  components: {
    FluentIcon,
  },
  props: {
    url: {
      type: String,
      default: '',
    },
    isInProgress: {
      type: Boolean,
      default: false,
    },
    widgetColor: {
      type: String,
      default: '',
    },
    isUserBubble: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    title() {
      return this.isInProgress
        ? this.$t('COMPONENTS.FILE_BUBBLE.UPLOADING')
        : decodeURI(this.fileName);
    },
    fileName() {
      return this.url.substring(this.url.lastIndexOf('/') + 1);
    },
    contrastingTextColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    textColor() {
      return this.isUserBubble && this.widgetColor
        ? this.contrastingTextColor
        : '';
    },
  },
  methods: {
    openLink() {
      const win = window.open(this.url, '_blank');
      win.focus();
    },
  },
};
</script>

<template>
  <div class="file flex flex-row items-center p-3 cursor-pointer">
    <div class="icon-wrap" :style="{ color: textColor }">
      <FluentIcon icon="document" size="28" type="solid" />
    </div>
    <div class="meta">
      <div class="link-wrap mb-1">
        <a
          class="download"
          rel="noreferrer noopener nofollow"
          target="_blank"
          :style="{ color: textColor }"
          :href="url"
        >
          <div class="title" :class="titleColor" :style="{ color: textColor }">
            {{ title }}
          </div>
          {{ $t('COMPONENTS.FILE_BUBBLE.DOWNLOAD') }}
        </a>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.file {
  padding: 0.75rem 1rem !important;
  .icon-wrap {
    font-size: 2.125rem;
    color: #1f93ff;
    line-height: 1;
    margin-left: 0.25rem;
    margin-right: 0.5rem;
  }

  .title {
    text-decoration: underline;
    font-weight: 500;
    font-size: 1rem;
    margin: 0 0 4px 0;
  }

  .download {
    color: #1f93ff;
    font-weight: 500;
    margin: 0;
    font-size: 0.875rem;
    text-decoration: none;
  }

  .link-wrap {
    line-height: 1;
  }
  .meta {
    padding-right: 0.25rem;
  }
}
</style>
