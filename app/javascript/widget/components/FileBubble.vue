<template>
  <div class="file flex flex-row items-center p-3 cursor-pointer">
    <div class="icon-wrap" :style="{ color: textColor }">
      <fluent-icon icon="document" size="28" />
    </div>
    <div class="meta">
      <div class="title" :style="{ color: textColor }">
        {{ title }}
      </div>
      <div class="link-wrap mb-1">
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
    textColor() {
      return getContrastingTextColor(this.widgetColor);
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

<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';

.file {
  .icon-wrap {
    font-size: $font-size-mega;
    color: $color-woot;
    line-height: 1;
    margin-left: $space-smaller;
    margin-right: $space-small;
  }

  .title {
    font-weight: $font-weight-medium;
    font-size: $font-size-default;
    margin: 0;
  }

  .download {
    color: $color-woot;
    font-weight: $font-weight-medium;
    padding: 0;
    margin: 0;
    font-size: $font-size-small;
    text-decoration: none;
  }

  .link-wrap {
    line-height: 1;
  }
  .meta {
    padding-right: $space-smaller;
  }
}
</style>
