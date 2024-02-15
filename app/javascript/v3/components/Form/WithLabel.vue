<template>
  <div class="space-y-1">
    <label
      v-if="label"
      :for="name"
      class="flex justify-between text-sm font-medium leading-6 text-slate-900 dark:text-white"
      :class="{ 'text-red-500': hasError }"
    >
      <slot name="label">
        {{ label }}
      </slot>
      <slot name="rightOfLabel" />
    </label>
    <div class="w-full">
      <div class="flex items-center relative w-full">
        <fluent-icon
          v-if="icon"
          size="16"
          :icon="icon"
          class="absolute left-2 transform text-slate-400 dark:text-slate-600 w-5 h-5"
        />
        <slot />
      </div>
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
    icon: {
      type: String,
      default: '',
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
