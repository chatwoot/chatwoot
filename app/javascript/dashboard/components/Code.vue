<script>
import 'highlight.js/styles/default.css';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';

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
    enableCodePen: {
      type: Boolean,
      default: false,
    },
    codepenTitle: {
      type: String,
      default: 'Chatwoot Codepen',
    },
  },
  computed: {
    codepenScriptValue() {
      const lang = this.lang === 'javascript' ? 'js' : this.lang;
      return JSON.stringify({
        title: this.codepenTitle,
        private: true,
        [lang]: this.script,
      });
    },
  },
  methods: {
    async onCopy(e) {
      e.preventDefault();
      await copyTextToClipboard(this.script);
      useAlert(this.$t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
    },
  },
};
</script>

<template>
  <div class="code--container">
    <div class="code--action-area">
      <form
        v-if="enableCodePen"
        class="code--codeopen-form"
        action="https://codepen.io/pen/define"
        method="POST"
        target="_blank"
      >
        <input type="hidden" name="data" :value="codepenScriptValue" />

        <button type="submit" class="button secondary tiny">
          {{ $t('COMPONENTS.CODE.CODEPEN') }}
        </button>
      </form>
      <button class="button secondary tiny" @click="onCopy">
        {{ $t('COMPONENTS.CODE.BUTTON_TEXT') }}
      </button>
    </div>
    <highlightjs v-if="script" :language="lang" :code="script" />
  </div>
</template>

<style lang="scss" scoped>
.code--container {
  position: relative;
  text-align: left;

  .code--action-area {
    top: var(--space-small);
    position: absolute;
    right: var(--space-small);
  }

  .code--codeopen-form {
    display: inline-block;
  }
}
</style>
