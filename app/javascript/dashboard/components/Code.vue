<template>
  <div class="code--container">
    <button class="button small button--copy-code" @click="onCopy">
      {{ $t('COMPONENTS.CODE.BUTTON_TEXT') }}
    </button>
    <highlightjs v-if="script" :language="lang" :code="script" />
  </div>
</template>

<script>
import 'highlight.js/styles/default.css';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

export default {
  props: {
    script: {
      type: String,
      default: '',
    },
    lang: {
      type: String,
      default: 'javascript',
    },
  },
  methods: {
    async onCopy(e) {
      e.preventDefault();
      await copyTextToClipboard(this.script);
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
