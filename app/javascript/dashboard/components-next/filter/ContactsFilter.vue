<script setup>
import { useTemplateRef, onBeforeUnmount, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { vOnClickOutside } from '@vueuse/components';
import { CONTACTS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useContactFilterContext } from './contactProvider.js';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';

import Button from 'next/button/Button.vue';
import ConditionRow from './ConditionRow.vue';

const props = defineProps({
  isSegmentView: { type: Boolean, default: false },
  segmentName: { type: String, default: '' },
});

const emit = defineEmits([
  'applyFilter',
  'updateSegment',
  'close',
  'clearFilters',
]);
const { filterTypes } = useContactFilterContext();

const filters = defineModel({
  type: Array,
  default: [],
});
const segmentNameLocal = ref(props.segmentName);

const DEFAULT_FILTER = {
  attributeKey: 'name',
  filterOperator: 'equal_to',
  values: '',
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

const updateSavedSegment = () => {
  if (isConditionsValid()) {
    emit('updateSegment', filters.value, segmentNameLocal.value);
  }
};

function validateAndSubmit() {
  if (!isConditionsValid()) return;

  store.dispatch(
    'contacts/setContactFilters',
    useSnakeCase(JSON.parse(JSON.stringify(filters.value)))
  );
  emit('applyFilter', filters.value);
  useTrack(CONTACTS_EVENTS.APPLY_FILTER, {
    appliedFilters: filters.value.map(filter => ({
      key: filter.attributeKey,
      operator: filter.filterOperator,
      queryOperator: filter.queryOperator,
    })),
  });
}

const filterModalHeaderTitle = computed(() => {
  return !props.isSegmentView
    ? t('CONTACTS_LAYOUT.FILTER.TITLE')
    : t('CONTACTS_LAYOUT.FILTER.EDIT_SEGMENT');
});

onBeforeUnmount(() => emit('close'));
const outsideClickHandler = [
  () => emit('close'),
  { ignore: ['#toggleContactsFilterButton'] },
];
</script>

<template>
  <div
    v-on-click-outside="outsideClickHandler"
    class="z-40 max-w-3xl lg:w-[750px] overflow-visible w-full border border-n-weak bg-n-alpha-3 backdrop-blur-[100px] shadow-lg rounded-xl p-6 grid gap-6"
  >
    <h3 class="text-base font-medium leading-6 text-n-slate-12">
      {{ filterModalHeaderTitle }}
    </h3>
    <div v-if="props.isSegmentView">
      <label class="pb-6 border-b border-n-weak">
        <div class="mb-2 text-sm text-n-slate-11">
          {{ $t('CONTACTS_LAYOUT.FILTER.SEGMENT.LABEL') }}
        </div>
        <input
          v-model="segmentNameLocal"
          class="py-1.5 px-3 text-n-slate-12 bg-n-alpha-1 text-sm rounded-lg reset-base w-full"
          :placeholder="t('CONTACTS_LAYOUT.FILTER.SEGMENT.INPUT_PLACEHOLDER')"
        />
      </label>
    </div>
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
      <Button sm ghost blue @click="addFilter">
        {{ $t('CONTACTS_LAYOUT.FILTER.BUTTONS.ADD_FILTER') }}
      </Button>
      <div class="flex gap-2">
        <Button sm faded slate @click="resetFilter">
          {{ $t('CONTACTS_LAYOUT.FILTER.BUTTONS.CLEAR_FILTERS') }}
        </Button>
        <Button
          v-if="isSegmentView"
          sm
          solid
          blue
          :disabled="!segmentNameLocal"
          @click="updateSavedSegment"
        >
          {{ $t('CONTACTS_LAYOUT.FILTER.BUTTONS.UPDATE_SEGMENT') }}
        </Button>
        <Button v-else sm solid blue @click="validateAndSubmit">
          {{ $t('CONTACTS_LAYOUT.FILTER.BUTTONS.APPLY_FILTERS') }}
        </Button>
      </div>
    </div>
  </div>
</template>
