<script>
import 'highlight.js/styles/default.css';
import 'highlight.js/lib/common';

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
        [lang]: this.scrubbedScript,
      });
    },
    scrubbedScript() {
      // remove trailing and leading extra lines and not spaces
      const scrubbed = this.script.replace(/^\s*[\r\n]/gm, '');
      const lines = scrubbed.split('\n');

      // remove extra indentations
      const minIndent = lines.reduce((min, line) => {
        if (line.trim().length === 0) return min;
        const indent = line.match(/^\s*/)[0].length;
        return Math.min(min, indent);
      }, Infinity);

      return lines.map(line => line.slice(minIndent)).join('\n');
    },
  },
  methods: {
    async onCopy(e) {
      e.preventDefault();
      await copyTextToClipboard(this.scrubbedScript);
      useAlert(this.$t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
    },
  },
};
</script>

<template>
  <div class="relative text-left">
    <div class="top-1.5 absolute right-1.5 flex items-center gap-1">
      <form
        v-if="enableCodePen"
        class="flex items-center"
        action="https://codepen.io/pen/define"
        method="POST"
        target="_blank"
      >
        <input type="hidden" name="data" :value="codepenScriptValue" />
        <button type="submit" class="button secondary tiny">
          {{ $t('COMPONENTS.CODE.CODEPEN') }}
        </button>
      </form>
      <button type="button" class="button secondary tiny" @click="onCopy">
        {{ $t('COMPONENTS.CODE.BUTTON_TEXT') }}
      </button>
    </div>
    <highlightjs v-if="script" :language="lang" :code="scrubbedScript" />
  </div>
</template>
