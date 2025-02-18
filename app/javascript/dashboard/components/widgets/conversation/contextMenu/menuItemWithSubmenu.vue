<script>
export default {
  props: {
    option: {
      type: Object,
      default: () => {},
    },
    subMenuAvailable: {
      type: Boolean,
      default: true,
    },
  },
};
</script>

<template>
  <div
    class="text-slate-800 dark:text-slate-100 menu-with-submenu min-width-calc w-full p-1 flex items-center h-7 rounded-md relative bg-n-alpha-3/50 backdrop-blur-[100px] justify-between hover:bg-n-brand/10 cursor-pointer dark:hover:bg-n-solid-3"
    :class="!subMenuAvailable ? 'opacity-50 cursor-not-allowed' : ''"
  >
    <div class="flex items-center h-4">
      <fluent-icon :icon="option.icon" size="14" class="menu-icon" />
      <p class="my-0 mx-2 text-xs">{{ option.label }}</p>
    </div>
    <fluent-icon icon="chevron-right" size="12" />
    <div
      v-if="subMenuAvailable"
      class="submenu bg-n-alpha-3 backdrop-blur-[100px] p-1 shadow-lg rounded-md absolute left-full top-0 hidden min-h-min max-h-[15rem] overflow-y-auto overflow-x-hidden cursor-pointer"
    >
      <slot />
    </div>
  </div>
</template>

<style scoped lang="scss">
.menu-with-submenu {
  min-width: calc(6.25rem * 2);

  &:hover {
    .submenu {
      @apply block;
    }
  }
}
</style>
