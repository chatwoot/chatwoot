<template>
  <div class="file message-text__wrap">
    <div class="icon-wrap">
      <i class="ion-document-text"></i>
    </div>
    <div class="meta">
      <div class="title">
        {{ title }}
      </div>
      <div class="link-wrap">
        <a
          class="download"
          rel="noreferrer noopener nofollow"
          target="_blank"
          :href="url"
        >
          {{ $t('COMPONENTS.FILE_BUBBLE.DOWNLOAD') }}
        </a>
      </div>
    </div>
  </div>
</template>

<script>
export default {
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
      const filename = this.url.substring(this.url.lastIndexOf('/') + 1);
      return filename;
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
  display: flex;
  flex-direction: row;
  padding: $space-slab;
  cursor: pointer;

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
