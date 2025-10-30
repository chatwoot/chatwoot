<script setup>
import { useTemplateRef, onBeforeUnmount, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { vOnClickOutside } from '@vueuse/components';
import { useAppointmentFilterContext } from './appointmentProvider.js';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';

import Button from 'dashboard/components-next/button/Button.vue';
import ConditionRow from './ConditionRow.vue';

const emit = defineEmits(['applyFilter', 'close', 'clearFilters']);
const { filterTypes } = useAppointmentFilterContext();

const filters = defineModel({
  type: Array,
  default: [],
});

const DEFAULT_FILTER = {
  attributeKey: 'location',
  filterOperator: 'equal_to',
  values: '',
  queryOperator: 'and',
  attributeModel: 'standard',
};

onMounted(() => {
  if (!filters.value || filters.value.length === 0) {
    filters.value = [{ ...DEFAULT_FILTER }];
  }
});

const { t } = useI18n();
const store = useStore();

const resetFilter = () => {
  filters.value = [{ ...DEFAULT_FILTER }];
  store.dispatch('appointments/setAppointmentFilters', []);
  emit('clearFilters');
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
    'appointments/setAppointmentFilters',
    useSnakeCase(JSON.parse(JSON.stringify(filters.value)))
  );
  emit('applyFilter', filters.value);
}

onBeforeUnmount(() => emit('close'));
const outsideClickHandler = [
  () => emit('close'),
  { ignore: ['#toggleAppointmentsFilterButton'] },
];
</script>

<template>
  <div
    v-on-click-outside="outsideClickHandler"
    class="z-40 max-w-3xl min-w-96 lg:w-[750px] overflow-visible w-full border border-n-weak bg-n-alpha-3 backdrop-blur-[100px] shadow-lg rounded-xl p-6 grid gap-6"
  >
    <h3 class="text-base font-medium leading-6 text-n-slate-12">
      {{ t('APPOINTMENTS.FILTER.TITLE') }}
    </h3>
    <ul class="grid gap-4 list-none">
      <template v-for="(filter, index) in filters" :key="filter.id">
        <ConditionRow
          v-if="index === 0"
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
          v-else
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
        {{ t('APPOINTMENTS.FILTER.BUTTONS.ADD_FILTER') }}
      </Button>
      <div class="flex gap-2 flex-shrink-0">
        <Button sm faded slate @click="resetFilter">
          {{ t('APPOINTMENTS.FILTER.BUTTONS.CLEAR_FILTERS') }}
        </Button>
        <Button sm solid blue @click="validateAndSubmit">
          {{ t('APPOINTMENTS.FILTER.BUTTONS.APPLY_FILTERS') }}
        </Button>
      </div>
    </div>
  </div>
</template>
