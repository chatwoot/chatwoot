<script setup>
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

import ActiveFilterPreview from 'dashboard/components-next/filter/ActiveFilterPreview.vue';

const emit = defineEmits(['clearFilters', 'openFilter']);

const { t } = useI18n();

const appliedFilters = useMapGetter('contacts/getAppliedContactFiltersV4');
</script>

<template>
  <ActiveFilterPreview
    :applied-filters="appliedFilters"
    :max-visible-filters="2"
    :more-filters-label="
      t('CONTACTS_LAYOUT.FILTER.ACTIVE_FILTERS.MORE_FILTERS', {
        count: appliedFilters.length - 2,
      })
    "
    :clear-button-label="
      t('CONTACTS_LAYOUT.FILTER.ACTIVE_FILTERS.CLEAR_FILTERS')
    "
    class="max-w-[960px] px-6"
    @open-filter="emit('openFilter')"
    @clear-filters="emit('clearFilters')"
  />
</template>
