<template>
  <div class="w-16 mx-auto text-center">
  <!-- <div class="flex flex-col justify-center items-center h-full"> -->
    <input
      :disabled="max === 0"
      :value="modelValue"
      @input="updateValue"
      type="number"
      :min="min"
      :max="max"
      class="leading-none"
      style="transform: translateY(8px);"
    />
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue';


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

const decrement = () => {
  if (props.modelValue > props.min) {
    emit('update:modelValue', props.modelValue - 1);
  }
};

const increment = () => {
  if (props.modelValue < props.max) {
    emit('update:modelValue', props.modelValue + 1);
  }
};

onMounted(() => {
  console.log("MY MAX: ", props.max)
})

const updateValue = event => {
  const value = parseInt(event.target.value) || props.min;
  const clampedValue = Math.max(props.min, Math.min(props.max, value));
  emit('update:modelValue', clampedValue);
  emit('input_val')
};
</script>
