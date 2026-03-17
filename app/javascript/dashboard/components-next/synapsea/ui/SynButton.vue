<script setup>
const props = defineProps({
  variant: {
    type: String,
    default: 'primary',
  },
});

const variantClass = {
  primary: 'bg-n-brand text-white hover:bg-n-brand/90',
  secondary: 'bg-n-alpha-2 text-n-slate-12 hover:bg-n-alpha-1',
};
</script>

<template>
  <button
    type="button"
    class="inline-flex items-center justify-center rounded-lg px-3 py-2 text-sm font-medium transition-colors"
    :class="variantClass[props.variant] || variantClass.primary"
  >
    <slot />
  </button>
</template>
