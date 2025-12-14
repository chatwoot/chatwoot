<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  name: 'MessageReplyButton',
  components: { FluentIcon },
};
</script>

<template>
  <button
    class="p-1 mb-1 rounded-full text-n-slate-11 bg-n-slate-3 hover:text-n-slate-12"
  >
    <FluentIcon icon="arrow-reply" size="11" class="flex-shrink-0" />
  </button>
</template>
