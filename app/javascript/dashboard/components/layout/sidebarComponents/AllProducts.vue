<script>
export default {
  methods: {
    handleClick() {
      this.$emit('toggleMenu');
    },
  },
};
</script>

<template>
  <div class="mb-4">
    <button
      v-tooltip.right="$t('ALL_PRODUCTS.TITLE')"
      class="text-slate-600 dark:text-slate-100 w-10 h-10 my-2 p-0 flex items-center justify-center rounded-lg hover:bg-slate-25 dark:hover:bg-slate-700 dark:hover:text-slate-100 hover:text-slate-600 relative"
      @click="handleClick"
    >
      <fluent-icon icon="office-apps" />
    </button>
  </div>
</template>
