<script setup>
import { ref, watch } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  modelValue: {
    type: Number,
    required: true,
  },
  min: {
    type: Number,
    default: 1,
  },
  max: {
    type: Number,
    default: 999,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue', 'save', 'cancel']);

const localValue = ref(props.modelValue);

watch(
  () => props.modelValue,
  newVal => {
    localValue.value = newVal;
  }
);

const decrement = () => {
  if (localValue.value > props.min) {
    localValue.value -= 1;
    emit('update:modelValue', localValue.value);
  }
};

const increment = () => {
  if (localValue.value < props.max) {
    localValue.value += 1;
    emit('update:modelValue', localValue.value);
  }
};

const handleSave = () => {
  emit('save', localValue.value);
};

const handleCancel = () => {
  localValue.value = props.modelValue;
  emit('cancel');
};
</script>

<template>
  <div class="flex items-center gap-4">
    <div
      class="flex items-center overflow-hidden border rounded-lg border-n-weak"
    >
      <button
        type="button"
        class="flex items-center justify-center w-10 h-10 transition-colors text-n-slate-11 hover:bg-n-alpha-2 disabled:opacity-50"
        :disabled="localValue <= min || isLoading"
        @click="decrement"
      >
        <span class="i-lucide-minus size-4" />
      </button>
      <span
        class="flex items-center justify-center w-12 h-10 text-base font-medium tabular-nums text-n-slate-12"
      >
        {{ localValue }}
      </span>
      <button
        type="button"
        class="flex items-center justify-center w-10 h-10 transition-colors text-n-slate-11 hover:bg-n-alpha-2 disabled:opacity-50"
        :disabled="localValue >= max || isLoading"
        @click="increment"
      >
        <span class="i-lucide-plus size-4" />
      </button>
    </div>
    <div class="flex items-center gap-2">
      <Button
        variant="link"
        color="slate"
        label="Cancel"
        :disabled="isLoading"
        @click="handleCancel"
      />
      <Button
        solid
        slate
        sm
        label="Save"
        :is-loading="isLoading"
        @click="handleSave"
      />
    </div>
  </div>
</template>
