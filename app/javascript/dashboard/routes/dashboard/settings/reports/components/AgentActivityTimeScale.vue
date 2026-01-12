<script setup>
import { computed, ref, onMounted, onBeforeUnmount, watch } from 'vue';

const props = defineProps({
  start: {
    type: Number,
    required: true,
  },
  end: {
    type: Number,
    required: true,
  },
});

const containerRef = ref(null);
const width = ref(0);

const updateWidth = () => {
  if (containerRef.value) {
    width.value = containerRef.value.offsetWidth;
  }
};

onMounted(() => {
  updateWidth();
  window.addEventListener('resize', updateWidth);
});

onBeforeUnmount(() => {
  window.removeEventListener('resize', updateWidth);
});

watch(() => [props.start, props.end], updateWidth);

const DENSITY_PX = 90;

const MS = {
  minute: 60 * 1000,
  hour: 60 * 60 * 1000,
  day: 24 * 60 * 60 * 1000,
  week: 7 * 24 * 60 * 60 * 1000,
  month: 30 * 24 * 60 * 60 * 1000,
  year: 365 * 24 * 60 * 60 * 1000,
};

const duration = computed(() => props.end - props.start);

const STEP_CANDIDATES = [
  1 * MS.minute,
  5 * MS.minute,
  10 * MS.minute,
  15 * MS.minute,
  30 * MS.minute,
  1 * MS.hour,
  3 * MS.hour,
  6 * MS.hour,
  12 * MS.hour,
  1 * MS.day,
  1 * MS.week,
  1 * MS.month,
  3 * MS.month,
  1 * MS.year,
];

const step = computed(() => {
  if (!width.value) return STEP_CANDIDATES.at(-1);

  const maxTicks = Math.max(1, Math.floor(width.value / DENSITY_PX));

  return (
    STEP_CANDIDATES.find(s => duration.value / s <= maxTicks) ??
    STEP_CANDIDATES.at(-1)
  );
});

const ticks = computed(() => {
  if (!width.value || !props.start || !props.end) return [];

  const result = [];
  let t = Math.floor(props.start / step.value) * step.value;

  while (t <= props.end) {
    if (t >= props.start) result.push(t);
    t += step.value;
  }

  return result;
});

const percent = ts => ((ts - props.start) / (props.end - props.start)) * 100;

const formatTick = ts => {
  const d = new Date(ts);

  if (step.value <= MS.minute) {
    return d.toLocaleTimeString('ru', {
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  if (step.value <= MS.hour) {
    return d.toLocaleTimeString('ru', {
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  if (step.value <= MS.day) {
    return d.toLocaleString('ru', {
      day: '2-digit',
      month: 'short',
      hour: '2-digit',
    });
  }

  if (step.value <= MS.month) {
    return d.toLocaleDateString('ru', {
      day: '2-digit',
      month: 'short',
    });
  }

  if (step.value <= MS.year) {
    return d.toLocaleDateString('ru', {
      month: 'short',
      year: 'numeric',
    });
  }

  return d.getFullYear();
};
</script>

<template>
  <div ref="containerRef" class="relative h-6 ml-48 select-none">
    <div
      v-for="t in ticks"
      :key="t"
      class="absolute -translate-x-1/2 whitespace-nowrap text-[11px] text-n-slate-11"
      :style="{ left: percent(t) + '%' }"
    >
      {{ formatTick(t) }}
    </div>
  </div>
</template>
