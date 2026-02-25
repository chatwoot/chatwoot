<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

defineProps({
  modelValue: {
    type: Boolean,
  },
});

const emit = defineEmits(['update:modelValue']);
const { t } = useI18n();

const options = computed(() => [
  { label: t('CHOICE_TOGGLE.YES'), value: true },
  { label: t('CHOICE_TOGGLE.NO'), value: false },
]);

const handleSelect = value => {
  emit('update:modelValue', value);
};
</script>

<template>
  <div
    class="flex gap-4 items-center px-4 py-2.5 w-full rounded-lg divide-x transition-colors bg-n-solid-1 outline outline-1 outline-n-weak hover:outline-n-slate-6 focus-within:outline-n-brand divide-n-weak"
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
