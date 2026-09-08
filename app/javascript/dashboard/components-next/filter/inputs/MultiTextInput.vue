<script setup>
import { computed, nextTick, ref } from 'vue';
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
const isFocused = ref(false);
const showInput = computed(() => isFocused.value || !modelValue.value.length);

const commitDraft = shouldFocus => {
  const value = draft.value.trim();
  if (value) {
    modelValue.value = [...modelValue.value, value];
    draft.value = '';
  }
  if (shouldFocus) inputRef.value?.focus();
};

const removeValue = index => {
  modelValue.value = modelValue.value.filter((_, valueIndex) => {
    return valueIndex !== index;
  });
};

const handleFocus = async () => {
  isFocused.value = true;
  await nextTick();
  inputRef.value?.focus();
};

const handleBlur = () => {
  commitDraft(false);
  isFocused.value = false;
};
</script>

<template>
  <div
    class="flex flex-wrap items-center w-full min-w-64 gap-1 py-[0.1875rem] rounded-lg bg-n-alpha-2 focus:outline-none"
    :class="modelValue.length ? 'px-[0.1875rem]' : 'px-3'"
    tabindex="0"
    @focus="handleFocus"
    @click="handleFocus"
  >
    <div
      v-for="(value, index) in modelValue"
      :key="index"
      class="flex items-center justify-center max-w-full h-6 gap-1 px-1 py-0.5 text-sm leading-4 border rounded-lg bg-n-solid-1 border-n-weak"
    >
      <span class="flex-grow min-w-0 truncate text-n-slate-12">
        {{ value }}
      </span>
      <span
        class="flex-shrink-0 transition-colors cursor-pointer i-lucide-x size-3.5 text-n-slate-9 hover:text-n-slate-12"
        @click.stop="removeValue(index)"
      />
    </div>
    <InlineInput
      v-if="showInput"
      ref="inputRef"
      v-model="draft"
      :placeholder="placeholder"
      class="flex-1 min-w-32"
      @enter-press="commitDraft(true)"
      @blur="handleBlur"
    />
  </div>
</template>
