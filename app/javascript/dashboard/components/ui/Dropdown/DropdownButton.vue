<script setup>
defineProps({
  buttonText: {
    type: String,
    default: '',
  },
  rightIcon: {
    type: String,
    default: '',
  },
  leftIcon: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <button
    class="inline-flex relative items-center p-1.5 w-fit h-8 gap-1.5 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 active:bg-slate-75 dark:active:bg-slate-800"
  >
    <slot name="leftIcon">
      <fluent-icon
        v-if="leftIcon"
        :icon="leftIcon"
        size="18"
        class="flex-shrink-0 text-slate-900 dark:text-slate-50"
      />
    </slot>
    <span
      v-if="buttonText"
      class="text-sm font-medium truncate text-slate-900 dark:text-slate-50"
    >
      {{ buttonText }}
    </span>
    <slot name="rightIcon">
      <fluent-icon
        v-if="rightIcon"
        :icon="rightIcon"
        size="18"
        class="flex-shrink-0 text-slate-900 dark:text-slate-50"
      />
    </slot>

    <slot name="dropdown" />
  </button>
</template>
