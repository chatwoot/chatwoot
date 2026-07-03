<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  labelTitles: {
    type: Array,
    default: () => [],
  },
});

const MAX_VISIBLE = 2;

const accountLabels = useMapGetter('labels/getLabels');

const resolvedLabels = computed(() => {
  const titles = props.labelTitles || [];
  if (!titles.length) return [];

  return titles.map(title => {
    const accountLabel = accountLabels.value?.find(
      label => label.title === title
    );
    return accountLabel || title;
  });
});

const visibleLabels = computed(() =>
  resolvedLabels.value.slice(0, MAX_VISIBLE)
);

const hiddenCount = computed(() =>
  Math.max(0, resolvedLabels.value.length - MAX_VISIBLE)
);

const hiddenLabelTitles = computed(() =>
  resolvedLabels.value
    .slice(MAX_VISIBLE)
    .map(label => (typeof label === 'string' ? label : label.title))
);

const hiddenTooltip = computed(() => hiddenLabelTitles.value.join(', '));
</script>

<template>
  <div
    v-if="resolvedLabels.length"
    class="flex items-center gap-1 min-w-0 max-w-[12rem]"
  >
    <Label
      v-for="(label, index) in visibleLabels"
      :key="typeof label === 'string' ? `${label}-${index}` : label.id"
      :label="label"
      compact
    />
    <span
      v-if="hiddenCount"
      v-tooltip="hiddenTooltip"
      class="inline-flex items-center justify-center h-6 px-1.5 rounded-md bg-n-slate-3 text-label-small text-n-slate-11 flex-shrink-0"
    >
      +{{ hiddenCount }}
    </span>
  </div>
  <span v-else class="text-sm text-n-slate-11">—</span>
</template>
