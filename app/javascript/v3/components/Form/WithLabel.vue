<template>
  <div>
    <label
      v-if="label"
      :for="name"
      class="flex justify-between text-sm font-medium leading-6 text-slate-900 dark:text-white"
      :class="{ 'text-red-500': hasError }"
    >
      <slot name="label">
        {{ label }}
      </slot>
    </label>
    <div class="mt-1">
      <slot />
      <span
        v-if="errorMessage && hasError"
        class="text-xs text-red-400 leading-2"
      >
        {{ errorMessage }}
      </span>
    </div>
  </div>
</template>
<script>
export default {
  props: {
    label: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      required: true,
    },
    hasError: {
      type: Boolean,
      default: false,
    },
    errorMessage: {
      type: String,
      default: '',
    },
  },
};
</script>
