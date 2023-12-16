<template>
  <button
    class="p-1 mb-1 rounded-full dark:text-slate-500 dark:bg-slate-900 text-slate-600 bg-slate-100 hover:text-slate-800"
    @click="$emit('click')"
  >
    <FluentIcon icon="arrow-reply" size="11" class="flex-shrink-0" />
  </button>
</template>

<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  name: 'MessageReplyButton',
  components: { FluentIcon },
};
</script>
