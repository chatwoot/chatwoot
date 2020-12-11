<template>
  <div class="code--container">
    <button class="button small button--copy-code" @click="onCopy">
      {{ $t('COMPONENTS.CODE.BUTTON_TEXT') }}
    </button>
    <highlightjs :language="lang" :code="script" />
  </div>
</template>

<script>
import 'highlight.js/styles/default.css';
import copy from 'copy-text-to-clipboard';

export default {
  props: {
    script: {
      type: String,
      required: true,
    },
    lang: {
      type: String,
      default: 'javascript',
    },
  },
  methods: {
    onCopy(e) {
      e.preventDefault();
      copy(this.script);
      bus.$emit('newToastMessage', this.$t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
    },
  },
};
</script>

<style lang="scss" scoped>
.code--container {
  position: relative;
  text-align: left;

  .button--copy-code {
    margin-top: 0;
    position: absolute;
    right: 0;
  }
}
</style>
