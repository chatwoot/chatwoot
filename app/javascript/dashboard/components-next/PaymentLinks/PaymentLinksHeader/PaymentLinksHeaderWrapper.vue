<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';

import PaymentLinksHeader from 'dashboard/components-next/PaymentLinks/PaymentLinksHeader/PaymentLinksHeader.vue';
import PaymentLinksFilter from 'dashboard/components-next/filter/PaymentLinksFilter.vue';

const props = defineProps({
  searchValue: { type: String, default: '' },
  activeSort: { type: String, default: 'created_at' },
  activeOrdering: { type: String, default: '' },
  headerTitle: { type: String, default: '' },
  hasAppliedFilters: { type: Boolean, default: false },
});

const emit = defineEmits([
  'update:sort',
  'search',
  'applyFilter',
  'clearFilters',
]);

const { t } = useI18n();
const store = useStore();

const showFiltersModal = ref(false);
const appliedFilter = ref([]);

const appliedFilters = useMapGetter(
  'paymentLinks/getAppliedPaymentLinkFiltersV4'
);

const closeAdvanceFiltersModal = () => {
  showFiltersModal.value = false;
  appliedFilter.value = [];
};

const clearFilters = async () => {
  emit('clearFilters');
};

const onApplyFilter = async payload => {
  payload = useSnakeCase(payload);
  emit('applyFilter', filterQueryGenerator(payload));
  showFiltersModal.value = false;
};

const onToggleFilters = () => {
  appliedFilter.value = [];
  appliedFilter.value = props.hasAppliedFilters
    ? [...appliedFilters.value]
    : [
        {
          attributeKey: 'status',
          filterOperator: 'equal_to',
          values: '',
          queryOperator: 'and',
          attributeModel: 'standard',
        },
      ];
  showFiltersModal.value = true;
};

const onExport = async () => {
  try {
    await store.dispatch('paymentLinks/export');
    useAlert(t('PAYMENT_LINKS_LAYOUT.HEADER.ACTIONS.EXPORT_SUCCESS'));
  } catch (error) {
    useAlert(
      error.message || t('PAYMENT_LINKS_LAYOUT.HEADER.ACTIONS.EXPORT_ERROR')
    );
  }
};

defineExpose({
  onToggleFilters,
});
</script>

<template>
  <PaymentLinksHeader
    :search-value="searchValue"
    :active-sort="activeSort"
    :active-ordering="activeOrdering"
    :header-title="headerTitle"
    :has-active-filters="hasAppliedFilters"
    @search="emit('search', $event)"
    @update:sort="emit('update:sort', $event)"
    @export="onExport"
    @filter="onToggleFilters"
  >
    <template #filter>
      <div
        class="absolute mt-1 ltr:-right-52 rtl:-left-52 sm:ltr:right-0 sm:rtl:left-0 top-full"
      >
        <PaymentLinksFilter
          v-if="showFiltersModal"
          v-model="appliedFilter"
          @apply-filter="onApplyFilter"
          @close="closeAdvanceFiltersModal"
          @clear-filters="clearFilters"
        />
      </div>
    </template>
  </PaymentLinksHeader>
</template>
