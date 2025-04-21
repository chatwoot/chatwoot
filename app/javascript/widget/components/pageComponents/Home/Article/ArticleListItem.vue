<script setup>
import { defineProps, defineEmits } from 'vue';
const props = defineProps({
  link: {
    type: String,
    default: '',
  },
  title: {
    type: String,
    default: '',
  },
});
const emit = defineEmits(['selectArticle']);
const onClick = () => {
  emit('selectArticle', props.link);
};
</script>

<template>
  <div
    class="flex items-center justify-between rounded cursor-pointer text-n-slate-11 hover:text-n-slate-12 gap-2"
    role="button"
    @click="onClick"
  >
    <button
      class="underline-offset-2 leading-6 ltr:text-left rtl:text-right text-base"
    >
      {{ title }}
    </button>
    <span class="i-lucide-chevron-right text-base shrink-0" />
  </div>
</template>
