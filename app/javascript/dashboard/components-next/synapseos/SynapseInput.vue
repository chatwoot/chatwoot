<script setup>
import { computed } from 'vue';

const props = defineProps({
  modelValue: { type: [String, Number], default: '' },
  label: { type: String, default: '' },
  hint: { type: String, default: '' },
  error: { type: String, default: '' },
  placeholder: { type: String, default: '' },
  type: { type: String, default: 'text' },
  iconLeading: { type: String, default: '' },
  iconTrailing: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  id: { type: String, default: '' },
});

defineEmits(['update:modelValue']);

const hasIconLeading = computed(() => !!props.iconLeading);
const hasIconTrailing = computed(() => !!props.iconTrailing);
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <label v-if="label" :for="id" class="text-sm font-medium text-s-primary">
      {{ label }}
    </label>
    <div class="relative">
      <span
        v-if="hasIconLeading"
        :class="[
          'absolute left-3 top-1/2 -translate-y-1/2 size-4 text-s-muted pointer-events-none',
          iconLeading,
        ]"
      />
      <input
        :id="id"
        :type="type"
        :value="modelValue"
        :placeholder="placeholder"
        :disabled="disabled"
        :class="[
          'w-full bg-s-surface border rounded-lg h-10 text-sm text-s-primary transition-all duration-150 ease-out',
          'placeholder:text-s-disabled',
          'focus:outline-none focus:ring-2 focus:ring-focus focus:ring-offset-0 focus:border-s-brand',
          'disabled:bg-s-subtle disabled:cursor-not-allowed disabled:text-s-disabled',
          hasIconLeading ? 'pl-10' : 'pl-3',
          hasIconTrailing ? 'pr-10' : 'pr-3',
          error ? 'border-s-error focus:ring-s-error/30 focus:border-s-error' : 'border-s-border hover:border-s-border-strong',
        ]"
        @input="$emit('update:modelValue', $event.target.value)"
      >
      <span
        v-if="hasIconTrailing"
        :class="[
          'absolute right-3 top-1/2 -translate-y-1/2 size-4 text-s-muted pointer-events-none',
          iconTrailing,
        ]"
      />
    </div>
    <span v-if="error" class="text-xs text-s-error-text">{{ error }}</span>
    <span v-else-if="hint" class="text-xs text-s-muted">{{ hint }}</span>
  </div>
</template>
