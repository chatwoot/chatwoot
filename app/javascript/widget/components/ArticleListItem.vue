<template>
  <li
    class="py-1 flex items-center justify-between -mx-1 px-1 hover:bg-slate-25 dark:hover:bg-slate-600 rounded cursor-pointer text-slate-700 dark:text-slate-50 dark:hover:text-slate-25 hover:text-slate-900"
    role="button"
    @click="onClick"
  >
    <button class="underline-offset-2 text-sm leading-6 text-left">
      {{ title }}
    </button>
    <span class="pl-1 arrow">
      <fluent-icon icon="arrow-right" size="14" />
    </span>
  </li>
</template>

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
  data() {
    return {};
  },
  methods: {
    onClick() {
      this.$emit('click', this.link);
    },
  },
};
</script>
