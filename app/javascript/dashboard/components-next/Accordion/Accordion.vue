<script setup>
import { computed, getCurrentInstance, ref, watch } from 'vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  title: { type: String, required: true },
  isOpen: { type: Boolean, default: false },
});

const isExpanded = ref(props.isOpen);
const { uid } = getCurrentInstance();
const contentId = computed(() => `accordion-content-${uid}`);

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
      type="button"
      class="flex items-center justify-between w-full gap-3 p-4 text-start rounded-lg outline-none hover:bg-n-alpha-2 focus-visible:ring-1 focus-visible:ring-n-brand"
      :aria-expanded="isExpanded"
      :aria-controls="contentId"
      @click="toggleAccordion"
    >
      <span class="text-sm font-medium text-n-slate-12">{{ title }}</span>
      <Icon
        icon="i-lucide-chevron-down"
        class="w-4 h-4 text-n-slate-11 transition-transform duration-200"
        :class="{ 'rotate-180': isExpanded }"
      />
    </button>
    <div v-if="isExpanded" :id="contentId" class="p-4 pt-0">
      <slot />
    </div>
  </div>
</template>
