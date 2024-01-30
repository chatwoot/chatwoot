<script setup>
import { ref, computed } from 'vue';

const props = defineProps({
  totalLength: {
    type: Number,
    default: 0,
  },
  currentIndex: {
    type: Number,
    default: 0,
  },
});

const totalItems = ref(props.totalLength);
const currentPage = ref(Math.floor(props.currentIndex / totalItems.value) + 1);

const isUpDisabled = computed(() => currentPage.value === 1);

const isDownDisabled = computed(
  () => currentPage.value === totalItems.value || totalItems.value <= 1
);

const handleUpClick = () => {
  if (currentPage.value > 1) {
    currentPage.value -= 1;
    // need to update it based on usage
  }
};
const handleDownClick = () => {
  if (currentPage.value < totalItems.value) {
    currentPage.value += 1;
    // need to update it based on usage
  }
};
</script>

<template>
  <div class="flex gap-2 items-center">
    <div class="flex gap-1 items-center">
      <woot-button
        size="tiny"
        variant="hollow"
        color-scheme="secondary"
        icon="chevron-up"
        :disabled="isUpDisabled"
        @click="handleUpClick"
      />
      <woot-button
        size="tiny"
        variant="hollow"
        color-scheme="secondary"
        icon="chevron-down"
        :disabled="isDownDisabled"
        @click="handleDownClick"
      />
    </div>
    <div class="flex items-center gap-1 whitespace-nowrap">
      <span class="text-sm font-medium text-gray-600">
        {{ totalItems <= 1 ? '1' : currentPage }}
      </span>
      <span
        v-if="totalItems > 1"
        class="text-sm text-slate-400 relative -top-px"
      >
        /
      </span>
      <span v-if="totalItems > 1" class="text-sm text-slate-400">
        {{ totalItems }}
      </span>
    </div>
  </div>
</template>
