<script setup>
import { defineProps, defineModel } from 'vue';
import WithLabel from './WithLabel.vue';

defineProps({
  label: {
    type: String,
    required: true,
  },
  icon: {
    type: String,
    default: '',
  },
  name: {
    type: String,
    required: true,
  },
  hasError: Boolean,
  errorMessage: {
    type: String,
    default: '',
  },
  spacing: {
    type: String,
    default: 'base',
    validator: value => ['base', 'compact'].includes(value),
  },
});

defineOptions({
  inheritAttrs: false,
});

const model = defineModel({
  type: [String, Number],
  required: true,
});
</script>

<template>
  <WithLabel
    :label="label"
    :icon="icon"
    :name="name"
    :has-error="hasError"
    :error-message="errorMessage"
  >
    <template #rightOfLabel>
      <slot />
    </template>
    <input
      v-bind="$attrs"
      v-model="model"
      class="block w-full border-none rounded-md shadow-sm appearance-none outline outline-1 focus:outline focus:outline-1 text-slate-900 dark:text-slate-100 placeholder:text-slate-400 sm:text-sm sm:leading-6 dark:bg-slate-800"
      :class="{
        'focus:outline-red-600 outline-red-600': hasError,
        'outline-slate-200 dark:outline-slate-600 dark:focus:outline-woot-500 focus:outline-woot-500':
          !hasError,
        'px-3 py-3': spacing === 'base',
        'px-3 py-2 mb-0': spacing === 'compact',
        'pl-9': icon,
      }"
    />
  </WithLabel>
</template>
