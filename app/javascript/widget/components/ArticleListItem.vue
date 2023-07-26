<template>
  <li
    class="py-1 flex items-center justify-between  -mx-1 px-1 hover:bg-slate-25"
  >
    <button
      class="text-slate-700 hover:text-slate-900 underline-offset-2 text-sm leading-6"
      @click="onClick"
    >
      {{ title }}
    </button>
    <span class="pl-1 text-slate-700 arrow">
      <fluent-icon icon="arrow-right" size="14" />
    </span>
  </li>
</template>
<script>
export default {
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
