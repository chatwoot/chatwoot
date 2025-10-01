<script setup>
import MarkdownIt from 'markdown-it';
import { computed } from 'vue';

const props = defineProps({
  rawSumary: {
    type: String,
    default: null,
  },
});

const md = new MarkdownIt();

const sumary = computed(() => {
  return md.render(props.rawSumary);
});
</script>

<template>
  <div class="pl-4">
    <div v-html="sumary" />
  </div>
</template>
