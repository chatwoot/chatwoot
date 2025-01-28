<template>
  <div>
    <div
      v-tooltip.right="'Compose'"
      class="text-slate-700 dark:text-slate-100 w-10 h-10 my-2 flex items-center justify-center rounded-lg hover:bg-slate-25 dark:hover:bg-slate-700 dark:hover:text-slate-100 hover:text-slate-600 relative cursor-pointer"
      :class="{
        'bg-woot-50 dark:bg-slate-800 text-woot-500 hover:bg-woot-50': isActive,
      }"
      @click="handleClick"
    >
      <fluent-icon
        :icon="icon"
        class="w-auto"
        :class="{
          'text-woot-500': isActive,
        }"
      />
      <span class="sr-only">{{ name }}</span>
    </div>
    <div class="h-[0.2px] w-full bg-black-200 my-4" />
  </div>
</template>
<script>
export default {
  props: {
    name: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      default: '',
    },
    isActive: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    handleClick() {
      this.$emit('toggle-compose-menu');
    },
  },
};
</script>
