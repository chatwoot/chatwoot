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
    class="flex gap-4 items-center px-4 py-2.5 w-full rounded-lg divide-x transition-colors bg-s-surface outline outline-1 outline-s-border hover:outline-s-border focus-within:outline-s-brand divide-s-border"
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
          class="size-4 accent-n-blue-9 text-s-brand"
          @change="handleSelect(option.value)"
        />
        <span class="text-sm text-s-primary">{{ option.label }}</span>
      </label>
    </div>
  </div>
</template>
