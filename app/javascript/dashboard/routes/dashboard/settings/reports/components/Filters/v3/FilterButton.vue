<script setup>
defineProps({
  buttonText: {
    type: String,
    default: '',
  },
});
</script>
<template>
  <button
    class="inline-flex relative items-center p-1.5 w-fit h-8 gap-1.5 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 active:bg-slate-75 dark:active:bg-slate-800"
    @click="$emit('click')"
  >
    <slot name="leftIcon" />
    <span
      v-if="buttonText"
      class="text-sm font-medium truncate text-slate-900 dark:text-slate-50"
    >
      {{ buttonText }}
    </span>
    <slot name="rightIcon" />

    <slot name="dropdown" />
  </button>
</template>
