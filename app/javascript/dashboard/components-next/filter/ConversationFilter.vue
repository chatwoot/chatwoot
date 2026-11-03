<script setup>
import { useTemplateRef, onBeforeUnmount, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { vOnClickOutside } from '@vueuse/components';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useConversationFilterContext } from './provider.js';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import { useTranslationPlan } from 'dashboard/composables/useTranslationPlan';
import ConversationApi from 'dashboard/api/conversations';
import { buildFiltersFromRecommendations } from './helper/filterHelper';

import Button from 'next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import ConditionRow from './ConditionRow.vue';

const props = defineProps({
  isFolderView: {
    type: Boolean,
    default: false,
  },
  folderName: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['applyFilter', 'updateFolder', 'close']);
const { filterTypes, attributeFilterTypes } = useConversationFilterContext();

const DESCRIBE_STATE = {
  PENDING: 'pending',
  EMPTY: 'empty',
};

// Building filters from a description follows the same paid-plan rule as translation.
const { isAvailable: canDescribeFilters } = useTranslationPlan();
const { run: runRecommendation } = useAbortableRequest();
// The description being built and its state, shown under the rows. Null when idle.
const describeStatus = ref(null);

const filters = defineModel({
  type: Array,
  default: [],
});
const folderNameLocal = ref(props.folderName);

const DEFAULT_FILTER = {
  attributeKey: 'status',
  filterOperator: 'equal_to',
  values: [],
  queryOperator: 'and',
};

const { t } = useI18n();
const store = useStore();

const resetFilter = () => {
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

// Replaces the row the description was typed in with the rows Jev builds.
// The other rows stay. A failure or an empty result leaves every row as it was.
const describeFilters = async (index, query) => {
  describeStatus.value = { query, state: DESCRIBE_STATE.PENDING };
  try {
    const response = await runRecommendation(signal =>
      ConversationApi.getFilterRecommendations(query, { signal })
    );
    // A newer description superseded this one and owns the status now.
    if (response === undefined) return;

    const recommendedFilters = buildFiltersFromRecommendations(
      response.data.payload ?? [],
      filterTypes.value
    );
    if (!recommendedFilters.length) {
      describeStatus.value = { query, state: DESCRIBE_STATE.EMPTY };
      return;
    }

    filters.value.splice(index, 1, ...recommendedFilters);
    describeStatus.value = null;
  } catch {
    describeStatus.value = { query, state: DESCRIBE_STATE.EMPTY };
  }
};

const conditionsRef = useTemplateRef('conditionsRef');

const isConditionsValid = () => {
  return conditionsRef.value.every(condition => condition.validate());
};

const updateSavedCustomViews = () => {
  if (isConditionsValid()) {
    emit('updateFolder', filters.value, folderNameLocal.value);
  }
};

function validateAndSubmit() {
  if (!isConditionsValid()) {
    return;
  }

  store.dispatch(
    'setConversationFilters',
    useSnakeCase(JSON.parse(JSON.stringify(filters.value)))
  );
  emit('applyFilter', filters.value);
  useTrack(CONVERSATION_EVENTS.APPLY_FILTER, {
    appliedFilters: filters.value.map(filter => ({
      key: filter.attributeKey,
      operator: filter.filterOperator,
      queryOperator: filter.queryOperator,
    })),
  });
}

const filterModalHeaderTitle = computed(() => {
  return !props.isFolderView
    ? t('FILTER.TITLE')
    : t('FILTER.EDIT_CUSTOM_FILTER');
});

onBeforeUnmount(() => emit('close'));
const outsideClickHandler = [
  () => emit('close'),
  { ignore: ['#toggleConversationFilterButton'] },
];
</script>

<template>
  <div
    v-on-click-outside="outsideClickHandler"
    class="z-40 w-[min(34rem,calc(100vw-2rem))] lg:w-[750px] overflow-visible border border-n-weak bg-n-alpha-3 backdrop-blur-[100px] shadow-lg rounded-xl p-6 grid gap-6"
  >
    <h3 class="text-base font-medium leading-6 text-n-slate-12">
      {{ filterModalHeaderTitle }}
    </h3>
    <div v-if="props.isFolderView">
      <div class="border-b border-n-weak pb-6">
        <Input
          v-model="folderNameLocal"
          :label="t('FILTER.FOLDER_LABEL')"
          :placeholder="t('FILTER.INPUT_PLACEHOLDER')"
        />
      </div>
    </div>
    <ul class="grid gap-4 list-none min-w-0">
      <template v-for="(filter, index) in filters" :key="filter.id">
        <ConditionRow
          v-if="index === 0"
          ref="conditionsRef"
          :key="`filter-${filter.attributeKey}-0`"
          v-model:attribute-key="filter.attributeKey"
          v-model:filter-operator="filter.filterOperator"
          v-model:values="filter.values"
          :filter-types="attributeFilterTypes"
          :show-query-operator="false"
          :describable="canDescribeFilters"
          @describe="query => describeFilters(index, query)"
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
          :filter-types="attributeFilterTypes"
          :describable="canDescribeFilters"
          @describe="query => describeFilters(index, query)"
          @remove="removeFilter(index)"
        />
      </template>
    </ul>
    <p
      v-if="describeStatus"
      class="flex items-center gap-2 text-sm text-n-slate-11 -mt-2"
    >
      <Spinner
        v-if="describeStatus.state === DESCRIBE_STATE.PENDING"
        :size="16"
      />
      {{
        describeStatus.state === DESCRIBE_STATE.PENDING
          ? t('FILTER.BUILDING_FILTERS', { query: describeStatus.query })
          : t('FILTER.NO_FILTERS_BUILT', { query: describeStatus.query })
      }}
    </p>
    <div class="flex gap-2 justify-between">
      <Button sm ghost blue @click="addFilter">
        {{ $t('FILTER.ADD_NEW_FILTER') }}
      </Button>
      <div class="flex gap-2">
        <Button sm faded slate @click="resetFilter">
          {{ t('FILTER.CLEAR_BUTTON_LABEL') }}
        </Button>
        <Button
          v-if="isFolderView"
          sm
          solid
          blue
          :disabled="!folderNameLocal"
          @click="updateSavedCustomViews"
        >
          {{ t('FILTER.UPDATE_BUTTON_LABEL') }}
        </Button>
        <Button v-else sm solid blue @click="validateAndSubmit">
          {{ t('FILTER.SUBMIT_BUTTON_LABEL') }}
        </Button>
      </div>
    </div>
  </div>
</template>
