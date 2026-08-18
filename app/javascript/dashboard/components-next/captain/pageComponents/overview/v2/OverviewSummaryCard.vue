<script setup>
import MetricCard from 'dashboard/components-next/captain/pageComponents/overview/MetricCard.vue';

defineProps({
  userName: { type: String, default: '' },
  points: { type: Array, default: () => [] },
  featuredMetrics: { type: Array, default: () => [] },
  metrics: { type: Array, default: () => [] },
  loading: { type: Boolean, default: false },
  summaryLoading: { type: Boolean, default: false },
});
</script>

<template>
  <section
    class="overflow-hidden border rounded-2xl bg-n-weak border-n-container shadow-[0_1px_1px_rgba(27,28,29,0.04)]"
  >
    <div class="grid gap-px border-b lg:grid-cols-6 border-n-weak">
      <div
        class="flex flex-col min-h-[139px] gap-3 p-5 bg-n-card lg:col-span-4"
      >
        <div class="flex items-center gap-1.5 text-n-iris-11">
          <span class="i-lucide-sparkles size-5" />
          <span class="text-base font-medium">
            {{ $t('CAPTAIN.OVERVIEW.V2.SUMMARY.GREETING', { name: userName }) }}
          </span>
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
          class="text-sm font-[420] leading-[21px] tracking-[-0.21px] text-n-slate-12"
        >
          {{ points.join(' ') }}
        </p>
        <p
          v-else
          class="text-sm font-[420] leading-[21px] tracking-[-0.21px] text-n-slate-11"
        >
          {{ $t('CAPTAIN.OVERVIEW.V2.SUMMARY.EMPTY') }}
        </p>
      </div>
      <MetricCard
        v-for="metric in featuredMetrics"
        :key="metric.key"
        v-bind="metric"
        :loading="loading"
        layout="headline"
        show-hint
        value-size-class="text-2xl"
        class="min-h-[139px] lg:col-span-1"
      />
    </div>
    <div class="grid gap-px sm:grid-cols-2 lg:grid-cols-3">
      <MetricCard
        v-for="metric in metrics"
        :key="metric.key"
        v-bind="metric"
        :loading="loading"
        show-hint
        compact
        value-size-class="text-2xl"
        class="min-h-[101px]"
      />
    </div>
  </section>
</template>
