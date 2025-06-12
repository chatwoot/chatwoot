<script setup>
import { ref, computed } from 'vue';
import { sampleActiveFilters } from './fixtures/filterTypes';
import ActiveFilterPreview from './ActiveFilterPreview.vue';

const appliedFilters = ref([...sampleActiveFilters]);
const maxVisibleFilters = ref(2);

const moreFiltersLabel = computed(
  () => `${appliedFilters.value.length - maxVisibleFilters.value} more filters`
);
</script>

<template>
  <Story
    title="Components/Filters/ActiveFilterPreview"
    :layout="{ type: 'grid', width: '960px' }"
  >
    <Variant title="Default (2 visible filters)">
      <ActiveFilterPreview
        :applied-filters="appliedFilters.slice(0, 2)"
        :max-visible-filters="2"
        clear-button-label="Clear Filters"
        more-filters-label=""
        @clear-filters="() => {}"
      />
    </Variant>

    <Variant title="Multiple Filters (with more indicator)">
      <ActiveFilterPreview
        :applied-filters="appliedFilters"
        :max-visible-filters="maxVisibleFilters"
        clear-button-label="Clear Filters"
        :more-filters-label="moreFiltersLabel"
        @clear-filters="() => {}"
      />
    </Variant>

    <Variant title="Show All Filters">
      <ActiveFilterPreview
        :applied-filters="appliedFilters"
        :max-visible-filters="10"
        clear-button-label="Clear Filters"
        @clear-filters="() => {}"
      />
    </Variant>

    <Variant title="Single Filter">
      <ActiveFilterPreview
        :applied-filters="[appliedFilters[0]]"
        :max-visible-filters="maxVisibleFilters"
        clear-button-label="Clear Filters"
        @clear-filters="() => {}"
      />
    </Variant>

    <Variant title="With Object Values">
      <ActiveFilterPreview
        :applied-filters="[appliedFilters[6]]"
        :max-visible-filters="maxVisibleFilters"
        clear-button-label="Clear Filters"
        @clear-filters="() => {}"
      />
    </Variant>
  </Story>
</template>
