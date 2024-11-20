<script setup>
import { ref, computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  options: {
    type: Array,
    required: true,
  },
  modelValue: {
    type: String,
    required: true,
  },
  label: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['update:modelValue']);

const isOpen = ref(false);

const labelValue = computed(() => props.label);

const toggleMenu = () => {
  isOpen.value = !isOpen.value;
};

const handleSelect = value => {
  emit('update:modelValue', value);
  isOpen.value = false;
};
</script>

<template>
  <div
    v-on-clickaway="() => (isOpen = false)"
    class="relative flex flex-col gap-1 w-fit"
  >
    <Button
      icon="i-lucide-chevron-down"
      size="sm"
      trailing-icon
      color="slate"
      variant="faded"
      class="!w-fit"
      :class="{ 'dark:!bg-n-alpha-2 !bg-n-slate-9/20': isOpen }"
      :label="labelValue"
      @click="toggleMenu"
    />
    <div
      v-if="isOpen"
      class="absolute ltr:left-full rtl:right-full select-none max-w-48 ltr:ml-1 rtl:mr-1 flex flex-col gap-1 bg-n-alpha-3 backdrop-blur-[100px] p-1 top-0 shadow-lg rounded-lg border border-n-weak"
    >
      <Button
        v-for="option in options"
        :key="option.value"
        :label="option.label"
        :icon="option.value === modelValue ? 'i-lucide-check' : ''"
        size="sm"
        variant="ghost"
        color="slate"
        trailing-icon
        class="!justify-end !px-2.5 !h-7"
        :class="{ '!bg-n-alpha-2': option.value === modelValue }"
        @click="handleSelect(option.value)"
      />
    </div>
  </div>
</template>
