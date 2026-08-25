<script setup>
import { ref } from 'vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';

defineProps({
  placeholder: { type: String, default: '' },
});

const modelValue = defineModel({
  type: Array,
  default: () => [],
});

const inputRef = ref(null);
const draft = ref('');

const commitDraft = shouldFocus => {
  const value = draft.value.trim();
  if (!value) return;

  modelValue.value = [...modelValue.value, value];
  draft.value = '';
  if (shouldFocus) inputRef.value?.focus();
};

const removeValue = index => {
  modelValue.value = modelValue.value.filter((_, valueIndex) => {
    return valueIndex !== index;
  });
};

const handleFocus = () => {
  inputRef.value?.focus();
};
</script>

<template>
  <div
    class="flex flex-wrap items-center w-full min-w-64 gap-2 px-3 py-0.5 rounded-lg bg-n-alpha-2 focus:outline-none"
    tabindex="0"
    @focus="handleFocus"
    @click="handleFocus"
  >
    <div
      v-for="(value, index) in modelValue"
      :key="index"
      class="flex items-center justify-center max-w-full gap-1 px-1 py-1 rounded-lg h-7 bg-n-solid-1"
    >
      <span class="flex-grow min-w-0 text-sm truncate text-n-slate-12">
        {{ value }}
      </span>
      <span
        class="flex-shrink-0 cursor-pointer i-lucide-x size-3.5 text-n-slate-11"
        @click.stop="removeValue(index)"
      />
    </div>
    <InlineInput
      ref="inputRef"
      v-model="draft"
      :placeholder="placeholder"
      class="flex-1 min-w-48"
      @enter-press="commitDraft(true)"
      @blur="commitDraft(false)"
    />
  </div>
</template>
