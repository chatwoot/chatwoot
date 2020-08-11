<template>
  <div class="file message-text__wrap" @click="openLink">
    <div class="icon-wrap">
      <i class="ion-document-text"></i>
    </div>
    <div class="meta">
      <h5 class="text-block-title">
        {{ decodeURI(fileName) }}
      </h5>
      <a
        class="download clear button small"
        rel="noreferrer noopener nofollow"
        target="_blank"
        :href="url"
      >
        {{ $t('CONVERSATION.DOWNLOAD') }}
      </a>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    url: {
      type: String,
      required: true,
    },
  },
  computed: {
    fileName() {
      const filename = this.url.substring(this.url.lastIndexOf('/') + 1);
      return filename;
    },
  },
  methods: {
    openLink() {
      const win = window.open(this.url, '_blank', 'noopener');
      win.focus();
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables';

.file {
  display: flex;
  flex-direction: row;
  padding: $space-smaller 0;
  cursor: pointer;

  .icon-wrap {
    font-size: $font-size-giga;
    color: $color-white;
    line-height: 1;
    margin-left: $space-smaller;
    margin-right: $space-slab;
  }

  .text-block-title {
    margin: 0;
    color: $color-white;
    font-weight: $font-weight-bold;
  }

  .button {
    padding: 0;
    margin: 0;
    color: $color-primary-light;
  }

  .meta {
    padding-right: $space-two;
  }

  .time {
    min-width: $space-larger;
  }
}
</style>
