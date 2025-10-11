<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { getContrastingTextColor } from '@chatwoot/utils';
import { extractFilenameFromUrl } from 'shared/helpers/FileHelper';
import { captureSentryException } from '../helpers/sentry';

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
      return extractFilenameFromUrl(this.url);
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
      try {
        const win = window.open(this.url, '_blank');
        if (!win) {
          throw new Error('Failed to open file link - popup blocked or invalid URL');
        }
        win.focus();
      } catch (error) {
        // Log file download/open failure to Sentry (lazy-loaded)
        captureSentryException(error, {
          level: 'warning',
          tags: {
            component: 'FileBubble',
            error_type: 'file_download_failure',
          },
          extra: {
            fileUrl: this.url,
            fileName: this.fileName,
          },
        });
      }
    },
  },
};
</script>

<template>
  <div class="file flex flex-row items-center p-3 cursor-pointer">
    <div class="icon-wrap" :style="{ color: textColor }">
      <FluentIcon icon="document" size="28" />
    </div>
    <div class="ltr:pr-1 rtl:pl-1">
      <div
        class="m-0 font-medium text-sm"
        :class="{ 'text-n-slate-12': !isUserBubble }"
        :style="{ color: textColor }"
      >
        {{ title }}
      </div>
      <div class="leading-none mb-1">
        <a
          class="download"
          rel="noreferrer noopener nofollow"
          target="_blank"
          :style="{ color: textColor }"
          :href="url"
        >
          {{ $t('COMPONENTS.FILE_BUBBLE.DOWNLOAD') }}
        </a>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.file {
  .icon-wrap {
    @apply text-[2.5rem] text-n-brand leading-none ltr:ml-1 rtl:mr-1 ltr:mr-2 rtl:ml-2;
  }

  .download {
    @apply text-n-brand font-medium p-0 m-0 text-xs no-underline;
  }
}
</style>
