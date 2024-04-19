<template>
  <div class="space-y-1">
    <label
      v-if="label"
      :for="name"
      class="flex justify-between text-sm font-medium leading-6 text-ash-900"
    >
      <slot name="label">
        {{ label }}
      </slot>
      <slot name="rightOfLabel" />
    </label>
    <div class="w-full">
      <div class="relative flex items-center w-full">
        <fluent-icon
          v-if="icon"
          size="16"
          :icon="icon"
          class="absolute w-5 h-5 transform left-2 text-ash-400"
        />
        <slot />
      </div>
      <span
        v-if="errorMessage && hasError"
        class="text-xs text-ruby-800 leading-2"
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
