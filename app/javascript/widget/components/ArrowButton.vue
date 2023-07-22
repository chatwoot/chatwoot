<template>
  <button
    type="button"
    class="flex w-full text-sm font-medium rounded-md mt-2 px-2 leading-6 text-slate-800 justify-center items-center hover:bg-slate-75 h-8 text-brand-link"
    @click="$emit('click')"
  >
    {{ text }}
    <span class="px-1 text-slate-700 text-brand-link">
      <fluent-icon icon="arrow-right" size="14" />
    </span>
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
