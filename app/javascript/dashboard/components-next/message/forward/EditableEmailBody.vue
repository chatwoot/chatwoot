<script setup>
import { useTemplateRef } from 'vue';
import { Letter } from 'vue-letter';
import { allowedCssProperties } from 'lettersanitizer';

defineProps({
  html: { type: String, required: true },
});

const letterRef = useTemplateRef('letterRef');

defineExpose({
  getContent: () => ({
    html: letterRef.value.$el.innerHTML,
    text: letterRef.value.$el.innerText.trim(),
  }),
  undo: () => {
    letterRef.value.$el.focus();
    document.execCommand('undo');
  },
});
</script>

<template>
  <Letter
    ref="letterRef"
    contenteditable="true"
    class-name="prose prose-bubble !max-w-none letter-render outline-none"
    :html="html"
    :allowed-css-properties="[
      ...allowedCssProperties,
      'transform',
      'transform-origin',
    ]"
  />
</template>
