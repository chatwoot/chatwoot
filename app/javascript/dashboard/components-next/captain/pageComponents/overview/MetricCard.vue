<script setup>
import { computed } from 'vue';
import MetricHint from 'dashboard/components-next/captain/pageComponents/overview/MetricHint.vue';

const props = defineProps({
  label: { type: String, required: true },
  value: { type: String, required: true },
  trend: { type: String, default: '' },
  hint: { type: String, default: '' },
  // Muted caveat line in the hint popover (estimates, measurement windows).
  hintNote: { type: String, default: '' },
  // Muted companion figure rendered beside the value at half its size, e.g.
  // "124 of 200" next to a rate, or the human-only CSAT baseline.
  secondary: { type: String, default: '' },
  // null = neutral, true = good direction, false = bad direction
  trendGood: { type: Boolean, default: null },
  clickable: { type: Boolean, default: false },
  loading: { type: Boolean, default: false },
});

const emit = defineEmits(['click']);

const trendClass = computed(() => {
  if (props.trendGood === null) return 'text-n-slate-11';
  return props.trendGood ? 'text-n-teal-11' : 'text-n-ruby-11';
});

const onActivate = () => {
  if (props.clickable) emit('click');
};
</script>

<template>
  <div
    class="flex flex-col gap-3 p-5 group bg-n-solid-1"
    :class="
      clickable
        ? 'cursor-pointer transition-colors hover:bg-n-slate-2/50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand'
        : ''
    "
    :role="clickable ? 'button' : undefined"
    :tabindex="clickable ? 0 : undefined"
    @click="onActivate"
    @keydown.enter.self.prevent="onActivate"
    @keydown.space.self.prevent="onActivate"
  >
    <div class="flex items-center gap-1.5">
      <span class="text-sm font-medium text-n-slate-11">{{ label }}</span>
      <MetricHint
        v-if="hint"
        :title="label"
        :description="hint"
        :note="hintNote"
      />
    </div>
    <div v-if="loading" class="flex items-end justify-between gap-2">
      <div class="w-20 rounded h-9 bg-n-slate-3 animate-pulse" />
      <div class="w-10 h-5 rounded bg-n-slate-3 animate-pulse" />
    </div>
    <div v-else class="flex items-end justify-between gap-2">
      <div class="flex items-baseline min-w-0 gap-1.5">
        <span
          class="text-3xl font-semibold tracking-tight tabular-nums text-n-slate-12"
        >
          {{ value }}
        </span>
        <span
          v-if="secondary"
          class="text-base truncate tabular-nums text-n-slate-10"
        >
          {{ secondary }}
        </span>
      </div>
      <span class="text-sm font-medium tabular-nums" :class="trendClass">
        {{ trend }}
      </span>
    </div>
  </div>
</template>
