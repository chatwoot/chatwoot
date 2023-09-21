<template>
  <kbd class="hotkey p-0.5 min-w-[1rem] uppercase" :class="customClass">
    <slot />
  </kbd>
</template>
<script>
export default {
  props: {
    customClass: {
      type: String,
      default: '',
    },
  },
};
</script>

<style lang="scss">
kbd.hotkey {
  @apply inline-flex leading-[0.625rem] rounded tracking-wide flex-shrink-0 items-center select-none justify-center;
}
</style>
