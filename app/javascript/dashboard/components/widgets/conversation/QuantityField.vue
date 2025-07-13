<template>
  <div class="w-24 mx-auto text-center relative">
    <input
      :disabled="max === 0"
      v-model.number="value"
      type="number"
      step="1"
      :min="min"
      :max="max"
      @input="handleInput"
      @blur="handleBlur"
      class="leading-none box-border"
      style="transform: translateY(8px); padding-right: 24px;"
    />
    <span
      class="absolute inset-y-0 right-2 flex items-center text-gray-400 pointer-events-none text-xs"
      style="transform: translateY(8px)"
    >
      /{{ max }}
    </span>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue';

const props = defineProps({
  modelValue: {
    type: Number,
    default: 1,
  },
  min: {
    type: Number,
    default: 1,
  },
  max: {
    type: Number,
    default: 100,
  },
});

const emit = defineEmits(['update:modelValue', 'input_val']);

// Internal value to handle clamping
const internalValue = ref(props.modelValue);

const clamp = (val) => {
  const num = Number(val);
  if (isNaN(num)) return props.min;
  return Math.max(props.min, Math.min(props.max, num));
};

const value = computed({
  get() {
    return internalValue.value;
  },
  set(val) {
    const clampedVal = clamp(val);
    internalValue.value = clampedVal;
    emit('update:modelValue', clampedVal);
  },
});

// Handle input event for real-time clamping
const handleInput = (event) => {
  const inputValue = event.target.value;
  if (inputValue === '') return; // Allow empty input temporarily
  
  const clampedVal = clamp(inputValue);
  // Always update to clamped value
  internalValue.value = clampedVal;
  emit('update:modelValue', clampedVal);
  emit('input_val', clampedVal);

  
  // Update the input field if it was clamped
  if (clampedVal !== Number(inputValue)) {
    event.target.value = clampedVal;
  }
};

// Handle blur event to ensure valid value when user leaves field
const handleBlur = (event) => {
  const inputValue = event.target.value;
  if (inputValue === '' || isNaN(Number(inputValue))) {
    // If empty or invalid, set to minimum
    event.target.value = props.min;
    internalValue.value = props.min;
    emit('update:modelValue', props.min);
  }
};

// Watch for prop changes
watch(() => props.modelValue, (newVal) => {
  internalValue.value = clamp(newVal);
}, { immediate: true });
</script>

<style scoped>
/* Approach 1: Style native spinner buttons */
.native-spinner::-webkit-inner-spin-button,
.native-spinner::-webkit-outer-spin-button {
  -webkit-appearance: none;
  margin: 0;
  /* Show the spinner buttons */
  -webkit-appearance: inner-spin-button;
  width: 20px;
  height: 100%;
  margin-right: 20px; /* Add space for the /max indicator */
}

.native-spinner {
  -moz-appearance: textfield;
}

/* For Firefox, we need to show the buttons differently */
.native-spinner::-moz-number-spin-box {
  margin-right: 20px;
}

/* Approach 2: Custom spinner button styling */
input[type='number'] {
  -moz-appearance: textfield;
}

/* Remove default styling from borderless input */
input[type='number']:focus {
  outline: none;
}
</style>