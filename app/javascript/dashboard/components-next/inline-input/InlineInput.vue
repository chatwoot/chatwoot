<script setup>
defineProps({
  modelValue: {
    type: [String, Number],
    default: '',
  },
  type: {
    type: String,
    default: 'text',
  },
  customInputClass: {
    type: [String, Object, Array],
    default: '',
  },
  customLabelClass: {
    type: [String, Object, Array],
    default: '',
  },
  placeholder: {
    type: String,
    default: '',
  },
  label: {
    type: String,
    default: '',
  },
  id: {
    type: String,
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:modelValue', 'enterPress']);

const onEnterPress = () => {
  emit('enterPress');
};
</script>

<template>
  <div
    class="relative flex items-center justify-between w-full gap-3 whitespace-nowrap"
  >
    <label
      v-if="label"
      :for="id"
      :class="customLabelClass"
      class="mb-0.5 text-sm font-medium text-gray-900 dark:text-gray-50"
    >
      {{ label }}
    </label>
    <!-- Added prefix slot to allow adding custom labels to the input -->
    <slot name="prefix" />
    <input
      :id="id"
      :value="modelValue"
      :type="type"
      :placeholder="placeholder"
      :disabled="disabled"
      :class="customInputClass"
      class="flex w-full reset-base text-sm h-6 !mb-0 border-0 rounded-lg bg-transparent dark:bg-transparent placeholder:text-slate-200 dark:placeholder:text-slate-500 disabled:cursor-not-allowed disabled:opacity-50 text-slate-900 dark:text-white transition-all duration-500 ease-in-out"
      @input="$emit('update:modelValue', $event.target.value)"
      @keydown.enter.prevent="onEnterPress"
    />
  </div>
</template>
