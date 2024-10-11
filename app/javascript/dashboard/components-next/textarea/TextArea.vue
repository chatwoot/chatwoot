<script setup>
import { computed } from 'vue';
const props = defineProps({
  modelValue: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
  placeholder: {
    type: String,
    default: '',
  },
  maxLength: {
    type: Number,
    default: 200,
  },
  id: {
    type: String,
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  customTextAreaClass: {
    type: String,
    default: '',
  },
  showCharacterCount: {
    type: Boolean,
    default: false,
  },
});
defineEmits(['update:modelValue']);
const characterCount = computed(() => props.modelValue.length);
</script>

<template>
  <div class="relative flex flex-col gap-1">
    <label
      v-if="label"
      :for="id"
      class="mb-0.5 text-sm font-medium text-gray-900 dark:text-gray-50"
    >
      {{ label }}
    </label>
    <textarea
      :id="id"
      :value="modelValue"
      :placeholder="placeholder"
      :maxlength="maxLength"
      class="flex w-full reset-base text-sm h-24 px-3 pt-3 !mb-0 border rounded-lg focus:border-woot-500 dark:focus:border-woot-600 bg-white dark:bg-slate-900 placeholder:text-slate-200 dark:placeholder:text-slate-500 text-slate-900 dark:text-white transition-all duration-500 ease-in-out resize-none disabled:cursor-not-allowed disabled:opacity-50 disabled:bg-slate-25 dark:disabled:bg-slate-900"
      :class="[customTextAreaClass, showCharacterCount ? 'pb-9' : 'pb-3']"
      :disabled="disabled"
      @input="$emit('update:modelValue', $event.target.value)"
    />
    <div
      v-if="showCharacterCount"
      class="absolute flex items-center justify-between mt-1 bottom-3 ltr:right-3 rtl:left-3"
    >
      <span class="text-xs tabular-nums text-slate-300 dark:text-slate-600">
        {{ characterCount }} / {{ maxLength }}
      </span>
    </div>
  </div>
</template>
