<script setup>
import { ref, watch } from 'vue';

const props = defineProps({
  title: { type: String, required: true },
  isOpen: { type: Boolean, default: false },
});

const isExpanded = ref(props.isOpen);

const toggleAccordion = () => {
  isExpanded.value = !isExpanded.value;
};

watch(
  () => props.isOpen,
  newValue => {
    isExpanded.value = newValue;
  }
);
</script>

<template>
  <div class="border rounded-lg border-n-slate-4">
    <button
      class="flex items-center justify-between w-full p-4 text-left"
      @click="toggleAccordion"
    >
      <span class="text-sm font-medium text-n-slate-12">{{ title }}</span>
      <span
        class="w-5 h-5 transition-transform duration-200 i-lucide-chevron-down"
        :class="{ 'rotate-180': isExpanded }"
      />
    </button>
    <div v-if="isExpanded" class="p-4 pt-0">
      <slot />
    </div>
  </div>
</template>
