<template>
  <div
    class="rounded-t-lg bg-white shadow-elevation2 hover:shadow-elevation3 border border-slate-100 "
    :class="{
      'rounded-b-lg': isRounded,
    }"
  >
    <div
      class="px-4 transition-all duration-300 ease-in-out h-full"
      :class="{
        'pt-0 pb-0': isCollapsed,
        'pt-6 pb-8': !isCollapsed,
      }"
    >
      <slot />
    </div>
  </div>
</template>

<script>
export default {
  props: {
    isRounded: {
      type: Boolean,
      default: true,
    },
    isCollapsed: {
      type: Boolean,
      default: false,
    },
  },
};
</script>
