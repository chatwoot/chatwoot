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
  <li
    class="py-1 flex items-center justify-between -mx-1 px-1 hover:bg-n-alpha-1 dark:hover:bg-n-alpha-black1 rounded cursor-pointer text-n-slate-11 dark:text-n-slate-12/80 dark:hover:text-n-slate-12 hover:text-n-slate-12"
    role="button"
    @click="onClick"
  >
    <button
      class="underline-offset-2 text-sm leading-6 ltr:text-left rtl:text-right"
    >
      {{ title }}
    </button>
    <span class="ltr:pl-1 rtl:pr-1 arrow">
      <FluentIcon icon="arrow-right" size="14" />
    </span>
  </li>
</template>
