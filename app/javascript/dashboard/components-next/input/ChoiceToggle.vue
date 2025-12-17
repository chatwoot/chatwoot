<script setup>
import { computed } from 'vue';

const props = defineProps({
  modelValue: {
    type: [Boolean, String, Number],
    default: null,
  },
  yesLabel: {
    type: String,
    default: 'Yes',
  },
  noLabel: {
    type: String,
    default: 'No',
  },
});

const emit = defineEmits(['update:modelValue']);

const options = computed(() => [
  { label: props.yesLabel, value: true },
  { label: props.noLabel, value: false },
]);

const handleSelect = value => {
  emit('update:modelValue', value);
};
</script>

<template>
  <div
    class="flex gap-4 items-center px-4 py-2.5 w-full rounded-lg divide-x transition-colors bg-bg-n-solid-1 outline outline-1 outline-n-weak dark:bg-n-solid-1 hover:outline-n-slate-6 focus-within:outline-n-brand divide-n-weak"
  >
    <div
      v-for="option in options"
      :key="option.value"
      class="flex flex-1 gap-2 justify-center items-center"
    >
      <label class="inline-flex gap-2 items-center text-base cursor-pointer">
        <input
          type="radio"
          :value="option.value"
          :checked="modelValue === option.value"
          class="size-4 accent-n-blue-9 text-n-blue-9"
          @change="handleSelect(option.value)"
        />
        <span class="text-sm text-n-slate-12">{{ option.label }}</span>
      </label>
    </div>
  </div>
</template>
