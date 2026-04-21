<script setup>
import { defineProps, defineModel, computed } from 'vue';
import { useToggle } from '@vueuse/core';

import Button from 'dashboard/components-next/button/Button.vue';
import WithLabel from './WithLabel.vue';

const props = defineProps({
  label: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    default: 'text',
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

const FIELDS = {
  TEXT: 'text',
  PASSWORD: 'password',
};

defineOptions({
  inheritAttrs: false,
});

const model = defineModel({
  type: [String, Number],
  required: true,
});

const [isPasswordVisible, togglePasswordVisibility] = useToggle();

const isPasswordField = computed(() => props.type === FIELDS.PASSWORD);

const currentInputType = computed(() => {
  if (isPasswordField.value) {
    return isPasswordVisible.value ? FIELDS.TEXT : FIELDS.PASSWORD;
  }
  return props.type;
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
      :name="name"
      :type="currentInputType"
      class="block w-full border-none rounded-md shadow-sm bg-s-primary/15 appearance-none outline outline-1 focus:outline focus:outline-1 text-s-primary placeholder:text-s-muted sm:text-sm sm:leading-6 px-3 py-3"
      :class="{
        'error outline-s-error dark:outline-s-error hover:outline-s-error dark:hover:outline-s-error disabled:outline-s-error dark:disabled:outline-s-error':
          hasError,
        'outline-s-border dark:outline-s-border hover:outline-s-border dark:hover:outline-s-border focus:outline-s-brand dark:focus:outline-s-brand':
          !hasError,
        'px-3 py-3': spacing === 'base',
        'px-3 py-2 mb-0': spacing === 'compact',
        'pl-9': icon,
        'pr-10': isPasswordField,
      }"
    />
    <Button
      v-if="isPasswordField"
      type="button"
      slate
      sm
      link
      :icon="isPasswordVisible ? 'i-lucide-eye-off' : 'i-lucide-eye'"
      class="absolute inset-y-0 right-0 pr-3"
      :aria-label="isPasswordVisible ? 'Hide password' : 'Show password'"
      :aria-pressed="isPasswordVisible"
      @click="togglePasswordVisibility()"
    />
  </WithLabel>
</template>
