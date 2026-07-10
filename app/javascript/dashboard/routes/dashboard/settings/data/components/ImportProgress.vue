<script setup>
import { computed } from 'vue';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  items: {
    type: Array,
    default: () => [],
  },
});

// Fit the grid to the number of groups so no empty cells show.
const columnsClass = computed(() => {
  if (props.items.length >= 3) return 'sm:grid-cols-3';
  if (props.items.length === 2) return 'sm:grid-cols-2';
  return 'sm:grid-cols-1';
});
</script>

<template>
  <section class="overflow-hidden rounded-xl border border-n-weak bg-n-solid-1">
    <h2 class="border-b border-n-weak px-4 py-3 text-heading-3 text-n-slate-12">
      {{ title }}
    </h2>
    <div class="grid grid-cols-1 gap-px bg-n-weak" :class="columnsClass">
      <div
        v-for="item in items"
        :key="item.key"
        class="flex flex-col gap-2 bg-n-solid-1 px-4 py-3"
      >
        <span class="text-label-small text-n-slate-11">{{ item.label }}</span>
        <div class="flex items-end justify-between gap-2">
          <span
            class="text-xl font-semibold tracking-tight tabular-nums text-n-slate-12"
          >
            {{ item.importedLabel }}
          </span>
          <span
            v-if="item.percent !== null"
            class="text-label-small tabular-nums text-n-slate-11"
          >
            {{ `${item.percent}%` }}
          </span>
        </div>
        <div
          v-if="item.percent !== null"
          class="h-1.5 w-full overflow-hidden rounded-full bg-n-alpha-2"
        >
          <div
            class="h-full rounded-full bg-n-brand transition-all duration-500"
            :style="{ width: `${item.percent}%` }"
          />
        </div>
        <span class="text-label-small text-n-slate-10">{{ item.caption }}</span>
      </div>
    </div>
  </section>
</template>
