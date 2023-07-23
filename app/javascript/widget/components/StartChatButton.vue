<template>
  <button
    type="button"
    class="flex w-full justify-between items-center rounded-md bg-slate-900 px-4 py-2 leading-6 text-sm font-medium text-white box-shadow focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-woot-600 bg-brand-primary text-brand-button hover-bg-brand-dark"
    @click="$emit('start')"
  >
    {{ text }}
    <fluent-icon icon="send" size="14" class="text-brand-button" />
  </button>
</template>

<script>
export default {
  props: {
    text: {
      type: String,
      default: '',
    },
  },
};
</script>
