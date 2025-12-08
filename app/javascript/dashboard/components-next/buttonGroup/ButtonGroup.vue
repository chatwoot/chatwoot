<script setup>
defineProps({
  noAnimation: {
    type: Boolean,
    default: false,
  },
});
</script>

<template>
  <div
    :class="
      noAnimation
        ? ''
        : 'has-[button:not(:disabled):active]:scale-[0.98] transition-transform duration-150 ease-out'
    "
  >
    <slot />
  </div>
</template>
