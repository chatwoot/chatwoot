<script setup>
import { computed } from 'vue';
const props = defineProps({
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
  message: {
    type: String,
    default: '',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  messageType: {
    type: String,
    default: 'info',
    validator: value => ['info', 'error', 'success'].includes(value),
  },
});
defineEmits(['update:modelValue']);
const messageClass = computed(() => {
  switch (props.messageType) {
    case 'error':
      return 'text-red-500 dark:text-red-400';
    case 'success':
      return 'text-green-500 dark:text-green-400';
    default:
      return 'text-slate-500 dark:text-slate-400';
  }
});
const inputBorderClass = computed(() => {
  switch (props.messageType) {
    case 'error':
      return 'border-red-500 dark:border-red-400';
    default:
      return 'border-slate-100 dark:border-slate-700/50';
  }
});
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
    <!-- Added prefix slot to allow adding icons to the input -->
    <slot name="prefix" />
    <input
      :id="id"
      :value="modelValue"
      :class="[customInputClass, inputBorderClass]"
      :type="type"
      :placeholder="placeholder"
      :disabled="disabled"
      class="flex w-full reset-base text-sm h-8 pl-3 pr-2 rtl:pr-3 rtl:pl-2 py-1.5 !mb-0 border rounded-lg focus:border-woot-500 dark:focus:border-woot-600 bg-white dark:bg-slate-900 file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-slate-200 dark:placeholder:text-slate-500 disabled:cursor-not-allowed disabled:opacity-50 text-slate-900 dark:text-white transition-all duration-500 ease-in-out"
      @input="$emit('update:modelValue', $event.target.value)"
    />
    <p
      v-if="message"
      class="mt-1 mb-0 text-xs transition-all duration-500 ease-in-out"
      :class="messageClass"
    >
      {{ message }}
    </p>
  </div>
</template>
