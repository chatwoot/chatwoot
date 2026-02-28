<script setup>
import { ref, watchEffect } from 'vue';

const props = defineProps({
  indeterminate: {
    type: Boolean,
    default: false,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['change']);

const modelValue = defineModel('modelValue', {
  type: Boolean,
  default: false,
});

const checkboxRef = ref(null);

watchEffect(() => {
  if (checkboxRef.value) {
    checkboxRef.value.indeterminate = props.indeterminate;
  }
});

const handleChange = event => {
  modelValue.value = event.target.checked;
  emit('change', event);
};
</script>

<template>
  <div class="relative h-[18px] w-[18px]">
    <input
      ref="checkboxRef"
      :checked="modelValue"
      type="checkbox"
      :disabled="disabled"
      class="reset-base peer absolute inset-0 z-10 h-[17px] w-[17px] cursor-pointer appearance-none [-webkit-appearance:none] rounded-[4px] border border-n-slate-6 bg-n-surface-1 transition-colors duration-200 hover:enabled:border-n-slate-8 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-n-slate-12 focus-visible:ring-offset-2 focus-visible:ring-offset-n-slate-2 checked:border-n-slate-12 checked:bg-n-slate-12 indeterminate:border-n-slate-12 indeterminate:bg-n-slate-12 disabled:cursor-not-allowed disabled:opacity-50"
      @change="handleChange"
    />
    <!-- Checkmark SVG -->
    <svg
      viewBox="0 0 14 14"
      fill="none"
      class="pointer-events-none absolute inset-0 z-20 m-auto h-[13px] w-[13px] stroke-n-slate-1 opacity-0 transition-opacity duration-200 peer-checked:opacity-100"
    >
      <path
        d="M2.9 7.4L5.7 10.1L11.1 4.7"
        stroke-width="1"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </svg>
    <!-- Minus/Indeterminate SVG -->
    <svg
      viewBox="0 0 14 14"
      fill="none"
      class="pointer-events-none absolute inset-0 z-20 m-auto h-3 w-3 stroke-n-slate-1 opacity-0 transition-opacity duration-200 peer-indeterminate:opacity-100"
    >
      <path
        d="M3.2 7H10.8"
        stroke-width="1.6"
        stroke-linecap="round"
        stroke-linejoin="round"
      />
    </svg>
  </div>
</template>
