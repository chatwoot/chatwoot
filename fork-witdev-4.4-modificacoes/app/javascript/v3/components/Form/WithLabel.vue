<script setup>
defineProps({
  label: { type: String, default: '' },
  name: { type: String, required: true },
  icon: { type: String, default: '' },
  hasError: { type: Boolean, default: false },
  helpMessage: { type: String, default: '' },
  errorMessage: { type: String, default: '' },
});
</script>

<template>
  <div class="space-y-1">
    <label
      v-if="label"
      :for="name"
      class="flex justify-between text-sm font-medium leading-6 text-n-slate-12"
      :class="{ 'text-n-ruby-12': hasError }"
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
          class="absolute left-2 transform text-n-slate-9 w-5 h-5"
        />
        <slot />
      </div>
      <div
        v-if="errorMessage && hasError"
        class="text-sm mt-1.5 ml-px text-n-ruby-9 leading-tight"
      >
        {{ errorMessage }}
      </div>
      <div
        v-else-if="helpMessage || $slots.help"
        class="text-sm mt-1.5 ml-px text-n-slate-10 leading-tight"
      >
        <slot name="help">
          {{ helpMessage }}
        </slot>
      </div>
    </div>
  </div>
</template>
