<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';

import ActiveFilterPreview from 'dashboard/components-next/filter/ActiveFilterPreview.vue';

const props = defineProps({
  activeSegment: { type: Object, default: null },
});

const emit = defineEmits(['clearFilters', 'openFilter']);

const { t } = useI18n();
const route = useRoute();

const appliedFilters = useMapGetter('contacts/getAppliedContactFiltersV4');
const activeSegmentId = computed(() => route.params.segmentId);

const activeSegmentQuery = computed(() => {
  const query = props.activeSegment?.query?.payload;
  if (!Array.isArray(query)) return [];

  const newFilters = query.map(filter => {
    const transformed = useCamelCase(filter);
    return {
      attributeKey: transformed.attributeKey,
      attributeModel: transformed.attributeModel,
      customAttributeType: transformed.customAttributeType,
      filterOperator: transformed.filterOperator,
      queryOperator: transformed.queryOperator ?? 'and',
      values: transformed.values,
    };
  });

  return newFilters;
});

const hasActiveSegments = computed(
  () => props.activeSegment && activeSegmentId.value !== 0
);

const activeFilterQueryData = computed(() => {
  return hasActiveSegments.value
    ? activeSegmentQuery.value
    : appliedFilters.value;
});
</script>

<template>
  <ActiveFilterPreview
    :applied-filters="activeFilterQueryData"
    :max-visible-filters="2"
    :more-filters-label="
      t('CONTACTS_LAYOUT.FILTER.ACTIVE_FILTERS.MORE_FILTERS', {
        count: activeFilterQueryData.length - 2,
      })
    "
    :clear-button-label="
      t('CONTACTS_LAYOUT.FILTER.ACTIVE_FILTERS.CLEAR_FILTERS')
    "
    :show-clear-button="!hasActiveSegments"
    class="max-w-[60rem] px-6"
    @open-filter="emit('openFilter')"
    @clear-filters="emit('clearFilters')"
  />
</template>
