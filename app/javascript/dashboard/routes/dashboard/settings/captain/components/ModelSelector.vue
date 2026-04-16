<script setup>
import ModelDropdown from './ModelDropdown.vue';

defineProps({
  featureKey: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  isAllowed: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits(['change']);

const handleModelChange = ({ feature, model }) => {
  emit('change', { feature, model });
};
</script>

<template>
  <div
    class="flex items-center justify-between gap-4 p-4 rounded-xl border border-n-weak bg-n-solid-1"
    :class="{ 'opacity-60 pointer-events-none relative': !isAllowed }"
  >
    <div class="flex-1 min-w-0">
      <h4 class="text-sm font-medium text-n-slate-12">
        {{ title }}
      </h4>
      <p class="text-sm text-n-slate-11 mt-0.5">{{ description }}</p>
    </div>
    <ModelDropdown
      v-if="isAllowed"
      :feature-key="featureKey"
      @change="handleModelChange"
    />
  </div>
</template>
