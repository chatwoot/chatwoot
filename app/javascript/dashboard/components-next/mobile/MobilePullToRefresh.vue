<script setup>
import { ref } from 'vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { useHaptics } from 'dashboard/composables/useHaptics';

const emit = defineEmits(['refresh']);

const isRefreshing = ref(false);
const pullDistance = ref(0);
const isPulling = ref(false);

const { medium } = useHaptics();

const PULL_THRESHOLD = 60;
let startY = 0;
let thresholdTriggered = false;

const onTouchStart = event => {
  const scrollTop = event.currentTarget.scrollTop;
  if (scrollTop === 0) {
    startY = event.touches[0].clientY;
    isPulling.value = true;
    thresholdTriggered = false;
  }
};

const onTouchMove = event => {
  if (!isPulling.value) return;
  const currentY = event.touches[0].clientY;
  const delta = currentY - startY;
  if (delta > 0) {
    pullDistance.value = Math.min(delta * 0.5, 80);
    if (!thresholdTriggered && pullDistance.value >= PULL_THRESHOLD) {
      medium();
      thresholdTriggered = true;
    }
  }
};

const onTouchEnd = async () => {
  if (!isPulling.value) return;
  isPulling.value = false;

  if (pullDistance.value >= PULL_THRESHOLD) {
    isRefreshing.value = true;
    emit('refresh');
    await new Promise(resolve => setTimeout(resolve, 800));
    isRefreshing.value = false;
  }
  pullDistance.value = 0;
};
</script>

<template>
  <div
    class="flex flex-col flex-1 overflow-y-auto relative"
    @touchstart.passive="onTouchStart"
    @touchmove.passive="onTouchMove"
    @touchend="onTouchEnd"
  >
    <div
      v-if="pullDistance > 0 || isRefreshing"
      class="flex items-center justify-center transition-all duration-150"
      :style="{ height: `${isRefreshing ? 40 : pullDistance}px` }"
    >
      <Spinner v-if="isRefreshing" class="text-n-brand" />
      <span
        v-else
        class="i-lucide-arrow-down size-5 text-n-slate-10 transition-transform"
        :class="{ 'rotate-180': pullDistance >= PULL_THRESHOLD }"
      />
    </div>
    <slot />
  </div>
</template>
