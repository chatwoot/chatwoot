<template>
  <button
    type="button"
    class="group start-button flex w-full justify-between items-center rounded-md bg-slate-900 px-4 py-2 leading-6 text-sm font-medium text-white box-shadow hover:bg-slate-300 hover:text-slate-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-woot-600 bg-brand-primary text-brand-button"
    @click="$emit('start')"
  >
    {{ text }}
    <fluent-icon
      icon="send"
      size="14"
      class="text-brand-button group-[:start-button]:group-hover:text-slate-700"
    />
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
