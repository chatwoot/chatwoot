<script setup>
import { computed, onUnmounted, ref, watch } from 'vue';
import MetricCard from 'dashboard/components-next/captain/pageComponents/overview/MetricCard.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  userName: { type: String, default: '' },
  points: { type: Array, default: () => [] },
  featuredMetrics: { type: Array, default: () => [] },
  metrics: { type: Array, default: () => [] },
  loading: { type: Boolean, default: false },
  summaryLoading: { type: Boolean, default: false },
});

const AUTO_ROTATION_DELAY = 15000;

const activePointIndex = ref(0);
let rotationTimer = null;

const activePoint = computed(
  () => props.points[activePointIndex.value] || props.points[0] || ''
);

const movePoint = direction => {
  const pointCount = props.points.length;
  if (!pointCount) return;

  activePointIndex.value =
    (activePointIndex.value + direction + pointCount) % pointCount;
};

const stopAutoRotation = () => {
  if (rotationTimer) clearInterval(rotationTimer);
  rotationTimer = null;
};

const startAutoRotation = () => {
  stopAutoRotation();
  if (props.points.length < 2) return;

  rotationTimer = setInterval(() => movePoint(1), AUTO_ROTATION_DELAY);
};

const selectPoint = direction => {
  movePoint(direction);
  startAutoRotation();
};

watch(
  () => props.points,
  () => {
    activePointIndex.value = 0;
    startAutoRotation();
  },
  { immediate: true }
);

onUnmounted(stopAutoRotation);
</script>

<template>
  <section
    class="overflow-hidden border rounded-2xl bg-n-weak border-n-container shadow-[0_0.0625rem_0.0625rem_rgba(27,28,29,0.04)]"
  >
    <div class="grid gap-px border-b lg:grid-cols-6 border-n-weak">
      <div
        class="flex flex-col min-h-[8.6875rem] gap-3 p-5 bg-n-card lg:col-span-4"
      >
        <div class="flex items-center justify-between gap-3">
          <div class="flex items-center gap-1.5 text-n-iris-11">
            <span class="i-lucide-sparkles size-5" />
            <span class="text-heading-2">
              {{
                $t('CAPTAIN.OVERVIEW.V2.SUMMARY.GREETING', { name: userName })
              }}
            </span>
          </div>
          <div
            v-if="!summaryLoading && points.length > 1"
            class="flex items-center gap-0.5"
          >
            <button
              v-tooltip="$t('CAPTAIN.OVERVIEW.V2.SUMMARY.PREVIOUS')"
              type="button"
              class="grid rounded-md size-6 place-content-center text-n-slate-11 transition-colors hover:bg-n-alpha-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand"
              :aria-label="$t('CAPTAIN.OVERVIEW.V2.SUMMARY.PREVIOUS')"
              @click="selectPoint(-1)"
            >
              <Icon icon="i-lucide-chevron-left" class="size-3.5 rtl:hidden" />
              <Icon
                icon="i-lucide-chevron-right"
                class="hidden size-3.5 rtl:inline-block"
              />
            </button>
            <button
              v-tooltip="$t('CAPTAIN.OVERVIEW.V2.SUMMARY.NEXT')"
              type="button"
              class="grid rounded-md size-6 place-content-center text-n-slate-11 transition-colors hover:bg-n-alpha-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand"
              :aria-label="$t('CAPTAIN.OVERVIEW.V2.SUMMARY.NEXT')"
              @click="selectPoint(1)"
            >
              <Icon icon="i-lucide-chevron-right" class="size-3.5 rtl:hidden" />
              <Icon
                icon="i-lucide-chevron-left"
                class="hidden size-3.5 rtl:inline-block"
              />
            </button>
          </div>
        </div>
        <div
          v-if="summaryLoading"
          class="flex flex-col gap-2"
          :aria-label="$t('CAPTAIN.OVERVIEW.WELCOME.LOADING')"
        >
          <div class="w-full h-4 rounded bg-n-slate-3 animate-pulse" />
          <div class="w-5/6 h-4 rounded bg-n-slate-3 animate-pulse" />
        </div>
        <p
          v-else-if="points.length"
          aria-live="polite"
          class="text-body-para text-n-slate-12"
        >
          {{ activePoint }}
        </p>
        <p v-else class="text-body-para text-n-slate-11">
          {{ $t('CAPTAIN.OVERVIEW.V2.SUMMARY.EMPTY') }}
        </p>
      </div>
      <MetricCard
        v-for="metric in featuredMetrics"
        :key="metric.key"
        v-bind="metric"
        :loading="loading"
        layout="headline"
        value-size-class="text-2xl"
        class="min-h-[8.6875rem] lg:col-span-1"
      />
    </div>
    <div class="grid gap-px sm:grid-cols-2 lg:grid-cols-3">
      <MetricCard
        v-for="metric in metrics"
        :key="metric.key"
        v-bind="metric"
        :loading="loading"
        compact
        value-size-class="text-2xl"
        class="min-h-[6.3125rem]"
      />
    </div>
  </section>
</template>
