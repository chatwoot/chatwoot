<script setup>
defineProps({
  label: { type: String, default: '' },
  error: { type: String, default: '' },
  type: { type: String, default: 'text' },
  placeholder: { type: String, default: '' },
});

const model = defineModel({ type: String, default: '' });
</script>

<template>
  <label class="block">
    <span
      v-if="label"
      class="block mb-1.5 text-xs font-medium text-cw-text-muted"
    >
      {{ label }}
    </span>
    <input
      v-model="model"
      :type="type"
      :placeholder="placeholder"
      class="w-full h-10 px-3 text-sm rounded-token-sm bg-cw-background text-cw-text placeholder:text-cw-text-faint border border-cw-border outline-none transition-shadow focus-visible:ring-2 focus-visible:ring-cw-primary focus-visible:border-transparent"
      :class="{ 'border-red-500': error }"
    />
    <span v-if="error" class="block mt-1 text-xs text-red-500">{{
      error
    }}</span>
  </label>
</template>
