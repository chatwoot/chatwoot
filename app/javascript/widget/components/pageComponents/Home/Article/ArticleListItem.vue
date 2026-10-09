<script setup>
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
    class="flex items-center justify-between gap-2 px-2 py-2 rounded-lg cursor-pointer text-n-slate-12 transition-colors hover:bg-n-alpha-2"
    role="button"
    @click="onClick"
  >
    <button
      class="underline-offset-2 leading-6 ltr:text-left rtl:text-right text-base"
    >
      {{ title }}
    </button>
    <span class="i-lucide-chevron-right text-base shrink-0 rtl:rotate-180" />
  </div>
</template>
