<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import hljs from 'highlight.js/lib/core';
import scheme from 'highlight.js/lib/languages/scheme';
import Button from 'dashboard/components-next/button/Button.vue';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';

const props = defineProps({ source: { type: String, required: true } });
const { t } = useI18n();
const highlighter = hljs.newInstance();
highlighter.registerLanguage('scheme', scheme);
const highlighted = computed(
  () => highlighter.highlight(props.source, { language: 'scheme' }).value
);
async function copy() {
  try {
    await copyTextToClipboard(props.source);
    useAlert(t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
  } catch {
    useAlert(t('CAPTAIN_ASK.TRACE.COPY_FAILED'));
  }
}
</script>

<template>
  <div class="min-w-0 overflow-hidden rounded-lg bg-n-alpha-2">
    <div
      class="flex items-center justify-between px-3 py-1 border-b border-n-weak"
    >
      <span class="text-xs font-medium text-n-slate-10">{{
        t('CAPTAIN_ASK.TRACE.SCHEME')
      }}</span>
      <Button
        xs
        ghost
        slate
        icon="i-lucide-copy"
        :label="t('COMPONENTS.CODE.BUTTON_TEXT')"
        @click="copy"
      />
    </div>
    <div class="max-h-[30rem] overflow-auto p-3">
      <pre
        class="m-0 text-xs font-mono leading-relaxed whitespace-pre-wrap break-words text-n-slate-12 [&_.hljs-comment]:text-n-slate-10 [&_.hljs-string]:text-n-teal-11 [&_.hljs-number]:text-n-amber-11 [&_.hljs-literal]:text-n-amber-11 [&_.hljs-built_in]:text-n-iris-11 [&_.hljs-name]:text-n-blue-11 [&_.hljs-symbol]:text-n-iris-11"
      ><code v-html="highlighted" /></pre>
    </div>
  </div>
</template>
