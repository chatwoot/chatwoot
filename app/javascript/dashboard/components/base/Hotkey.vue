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

<template>
  <kbd
    class="hotkey px-1.5 py-1 min-w-9 font-420 h-8 uppercase inline-flex rounded-lg outline outline-1 outline-n-weak bg-n-surface-2 text-sm flex-shrink-0 items-center select-none justify-center"
    :class="customClass"
  >
    <slot />
  </kbd>
</template>
