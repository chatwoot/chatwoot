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
      if (this.url) {
        const filename = this.url.substring(this.url.lastIndexOf('/') + 1);
        return filename || this.$t('CONVERSATION.UNKNOWN_FILE_TYPE');
      }
      return this.$t('CONVERSATION.UNKNOWN_FILE_TYPE');
    },
  },
  methods: {
    openLink() {
      const win = window.open(this.url, '_blank', 'noopener');
      if (win) win.focus();
    },
  },
};
</script>

<template>
  <div class="file message-text__wrap">
    <div class="icon-wrap">
      <fluent-icon icon="document" class="file--icon" size="32" />
    </div>
    <div class="meta">
      <h5 class="attachment-name text-slate-700 dark:text-slate-400">
        {{ decodeURI(fileName) }}
      </h5>
      <a
        class="download clear link button small"
        rel="noreferrer noopener nofollow"
        target="_blank"
        :href="url"
      >
        {{ $t('CONVERSATION.DOWNLOAD') }}
      </a>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import 'dashboard/assets/scss/variables';

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

  .attachment-name {
    margin: 0;
    color: $color-white;
    font-weight: $font-weight-bold;
    word-break: break-word;
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
