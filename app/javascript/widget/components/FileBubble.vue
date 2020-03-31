<template>
  <div class="file message-text__wrap" @click="openLink">
    <div class="icon-wrap">
      <i class="ion-document-text"></i>
    </div>
    <div class="meta">
      <div class="title">
        {{ decodeURI(fileName) }}
      </div>
      <div class="link-wrap">
        <a
          class="download"
          rel="noreferrer noopener nofollow"
          target="_blank"
          :href="url"
        >
          download
        </a>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: ['url'],
  computed: {
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
  padding: $space-one $space-slab;
  cursor: pointer;

  .icon-wrap {
    font-size: $font-size-bigger;
    color: $color-woot;
    line-height: 1;
    margin-left: $space-smaller;
    margin-right: $space-small;
  }

  .title {
    font-weight: $font-weight-medium;
    font-size: $font-size-small;
    margin: 0;
  }

  .download {
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
