<script setup>
import { useI18n } from 'vue-i18n';
import { useClipboard } from '@vueuse/core';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({ source: { type: String, required: true } });
const { t } = useI18n();
const { copy, copied } = useClipboard();
</script>

<template>
  <div class="min-w-0 overflow-hidden rounded-lg bg-n-alpha-2">
    <div
      class="flex items-center justify-between border-b border-n-weak px-3 py-1"
    >
      <span class="text-xs font-medium text-n-slate-10">{{
        t('WOOTQL.TITLE')
      }}</span>
      <Button
        xs
        ghost
        slate
        icon="i-lucide-copy"
        :label="copied ? t('WOOTQL.COPIED') : t('COMPONENTS.CODE.BUTTON_TEXT')"
        @click="copy(source)"
      />
    </div>
    <div class="max-h-[30rem] overflow-auto p-3">
      <pre
        class="m-0 whitespace-pre-wrap break-words font-mono text-xs leading-relaxed text-n-slate-12"
      ><code>{{ source }}</code></pre>
    </div>
  </div>
</template>
