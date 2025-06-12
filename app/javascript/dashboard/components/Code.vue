<script setup>
import { computed } from 'vue';
import 'highlight.js/styles/default.css';
import 'highlight.js/lib/common';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

const props = defineProps({
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
});

const { t } = useI18n();

const scrubbedScript = computed(() => {
  // remove trailing and leading extra lines and not spaces
  const scrubbed = props.script.replace(/^\s*[\r\n]/gm, '');
  const lines = scrubbed.split('\n');

  // remove extra indentations
  const minIndent = lines.reduce((min, line) => {
    if (line.trim().length === 0) return min;
    const indent = line.match(/^\s*/)[0].length;
    return Math.min(min, indent);
  }, Infinity);

  return lines.map(line => line.slice(minIndent)).join('\n');
});

const codepenScriptValue = computed(() => {
  const lang = props.lang === 'javascript' ? 'js' : props.lang;
  return JSON.stringify({
    title: props.codepenTitle,
    private: true,
    [lang]: scrubbedScript.value,
  });
});

const onCopy = async e => {
  e.preventDefault();
  await copyTextToClipboard(scrubbedScript.value);
  useAlert(t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
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
        <NextButton
          slate
          xs
          type="submit"
          faded
          :label="t('COMPONENTS.CODE.CODEPEN')"
        />
      </form>
      <NextButton
        slate
        xs
        faded
        :label="t('COMPONENTS.CODE.BUTTON_TEXT')"
        @click="onCopy"
      />
    </div>
    <highlightjs v-if="script" :language="lang" :code="scrubbedScript" />
  </div>
</template>
