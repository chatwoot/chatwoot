<script>
export default {
  props: {
    label: {
      type: String,
      default: '',
    },
    bg: {
      type: String,
      default: 'bg-white dark:bg-s-subtle',
    },
  },
};
</script>

<template>
  <div class="relative my-4 section-separator">
    <div class="absolute inset-0 flex items-center" aria-hidden="true">
      <div class="w-full border-t border-s-border-strong" />
    </div>
    <div v-if="label" class="relative flex justify-center text-sm">
      <span class="px-2 text-s-muted" :class="bg">
        {{ label }}
      </span>
    </div>
  </div>
</template>
