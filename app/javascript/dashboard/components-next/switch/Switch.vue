<script setup>
import { useI18n } from 'vue-i18n';

const emit = defineEmits(['change']);

const { t } = useI18n();

const modelValue = defineModel({
  type: Boolean,
  default: false,
});

const updateValue = () => {
  modelValue.value = !modelValue.value;
  emit('change', !modelValue.value);
};
</script>

<template>
  <button
    type="button"
    class="relative h-4 transition-colors duration-200 ease-in-out rounded-full w-7 focus:outline-none focus:ring-1 focus:ring-primary-500 focus:ring-offset-n-slate-2 focus:ring-offset-2"
    :class="modelValue ? 'bg-n-brand' : 'bg-n-alpha-1 dark:bg-n-alpha-2'"
    role="switch"
    :aria-checked="modelValue"
    @click="updateValue"
  >
    <span class="sr-only">{{ t('SWITCH.TOGGLE') }}</span>
    <span
      class="absolute top-px left-0.5 h-3 w-3 transform rounded-full shadow-sm transition-transform duration-200 ease-in-out"
      :class="
        modelValue
          ? 'translate-x-2.5 bg-white'
          : 'translate-x-0 bg-white dark:bg-n-black'
      "
    />
  </button>
</template>
