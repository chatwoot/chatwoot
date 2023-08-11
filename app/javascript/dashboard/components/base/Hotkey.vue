<template>
  <kbd class="hotkey" :class="customClass">
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
  @apply inline-flex p-0.5 leading-[0.625rem] min-w-[1rem] rounded tracking-wide uppercase flex-shrink-0 items-center select-none justify-center;
}
</style>
