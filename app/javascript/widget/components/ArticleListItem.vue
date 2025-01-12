<script>
import FluentIcon from 'shared/components/FluentIcon/Index.vue';

export default {
  components: { FluentIcon },
  props: {
    link: {
      type: String,
      default: '',
    },
    title: {
      type: String,
      default: '',
    },
  },
  emits: ['selectArticle'],
  data() {
    return {};
  },
  methods: {
    onClick() {
      this.$emit('selectArticle', this.link);
    },
  },
};
</script>

<template>
  <div
    class="py-1 flex items-center justify-between -mx-1 px-1 rounded cursor-pointer text-n-slate-11 hover:text-n-slate-12"
    role="button"
    @click="onClick"
  >
    <button class="underline-offset-2 leading-6 text-left">
      {{ title }}
    </button>
    <span class="pl-1 arrow">
      <span class="i-lucide-chevron-right" />
    </span>
  </div>
</template>
