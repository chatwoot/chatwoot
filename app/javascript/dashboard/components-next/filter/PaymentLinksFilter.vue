<script setup>
import { useTemplateRef, onBeforeUnmount, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { vOnClickOutside } from '@vueuse/components';
import { usePaymentLinkFilterContext } from './paymentLinkProvider.js';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';

import Button from 'next/button/Button.vue';
import ConditionRow from './ConditionRow.vue';

const emit = defineEmits(['applyFilter', 'close', 'clearFilters']);
const { filterTypes } = usePaymentLinkFilterContext();

const filters = defineModel({
  type: Array,
  default: [],
});

const DEFAULT_FILTER = {
  attributeKey: 'status',
  filterOperator: 'equal_to',
  values: [],
  queryOperator: 'and',
  attributeModel: 'standard',
};

const { t } = useI18n();
const store = useStore();

const resetFilter = () => {
  emit('clearFilters');
  filters.value = [{ ...DEFAULT_FILTER }];
};

const removeFilter = index => {
  if (filters.value.length === 1) {
    resetFilter();
  } else {
    filters.value.splice(index, 1);
  }
};

const addFilter = () => {
  filters.value.push({ ...DEFAULT_FILTER });
};

const conditionsRef = useTemplateRef('conditionsRef');

const isConditionsValid = () => {
  return conditionsRef.value.every(condition => condition.validate());
};

function validateAndSubmit() {
  if (!isConditionsValid()) return;

  store.dispatch(
    'paymentLinks/setPaymentLinkFilters',
    useSnakeCase(JSON.parse(JSON.stringify(filters.value)))
  );
  emit('applyFilter', filters.value);
}

const filterModalHeaderTitle = computed(() => {
  return t('PAYMENT_LINKS.FILTER.TITLE');
});

onBeforeUnmount(() => emit('close'));
const outsideClickHandler = [
  () => emit('close'),
  { ignore: ['#togglePaymentLinksFilterButton'] },
];
</script>

<template>
  <div
    v-on-click-outside="outsideClickHandler"
    class="z-40 max-w-3xl min-w-96 lg:w-[750px] overflow-visible w-full border border-n-weak bg-n-alpha-3 backdrop-blur-[100px] shadow-lg rounded-xl p-6 grid gap-6"
  >
    <h3 class="text-base font-medium leading-6 text-n-slate-12">
      {{ filterModalHeaderTitle }}
    </h3>
    <ul class="grid gap-4 list-none">
      <template v-for="(filter, index) in filters" :key="filter.id">
        <ConditionRow
          v-if="index === 0 && filterTypes.length > 0"
          ref="conditionsRef"
          :key="`filter-${filter.attributeKey}-0`"
          v-model:attribute-key="filter.attributeKey"
          v-model:filter-operator="filter.filterOperator"
          v-model:values="filter.values"
          :filter-types="filterTypes"
          :show-query-operator="false"
          @remove="removeFilter(index)"
        />
        <ConditionRow
          v-else-if="filterTypes.length > 0"
          :key="`filter-${filter.attributeKey}-${index}`"
          ref="conditionsRef"
          v-model:attribute-key="filter.attributeKey"
          v-model:filter-operator="filter.filterOperator"
          v-model:query-operator="filters[index - 1].queryOperator"
          v-model:values="filter.values"
          show-query-operator
          :filter-types="filterTypes"
          @remove="removeFilter(index)"
        />
      </template>
    </ul>
    <div class="flex justify-between gap-2">
      <Button sm ghost blue class="flex-shrink-0" @click="addFilter">
        {{ $t('PAYMENT_LINKS.FILTER.BUTTONS.ADD_FILTER') }}
      </Button>
      <div class="flex gap-2 flex-shrink-0">
        <Button sm faded slate @click="resetFilter">
          {{ $t('PAYMENT_LINKS.FILTER.BUTTONS.CLEAR_FILTERS') }}
        </Button>
        <Button sm solid blue @click="validateAndSubmit">
          {{ $t('PAYMENT_LINKS.FILTER.BUTTONS.APPLY_FILTERS') }}
        </Button>
      </div>
    </div>
  </div>
</template>
