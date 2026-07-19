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
</script>

<template>
  <div
    v-if="resolvedLabels.length"
    class="flex items-center gap-1 min-w-0 max-w-full overflow-x-auto whitespace-nowrap [scrollbar-width:thin]"
  >
    <Label
      v-for="(label, index) in resolvedLabels"
      :key="typeof label === 'string' ? `${label}-${index}` : label.id"
      :label="label"
      compact
      class="flex-shrink-0"
    />
  </div>
  <span v-else class="text-sm text-n-slate-11">--</span>
</template>
