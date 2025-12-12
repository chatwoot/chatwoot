<script setup>
import { useTemplateRef, onBeforeUnmount, computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { vOnClickOutside } from '@vueuse/components';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { useConversationFilterContext } from './provider.js';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMapGetter } from 'dashboard/composables/store';

import Button from 'next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
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
const { filterTypes } = useConversationFilterContext();
const teams = useMapGetter('teams/getMyTeams')
const userACL = useMapGetter('acl/getUserACL')
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
const isPartnerFilter = computed(() => {
  const userACLTimePrivado = userACL.value.time_privado
  return userACLTimePrivado
})

const resetFilter = () => {
  if (!isPartnerFilter.value) {
    filters.value = [
      {
        attributeKey: 'team_id',
        filterOperator: 'equal_to',
        values: filters.value[0]?.values || {},
        queryOperator: 'and'
      }
    ]
  } else {
    filters.value = [{ ...DEFAULT_FILTER }];
  }
};

const removeFilter = index => {
  if (!isPartnerFilter.value && filters.value[index].attributeKey === 'team_id') {
    return;
  }
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
onMounted(() => {
  // Garantir que vai chamar a fetch das acls
  //store.dispatch('acl/fetchAcl')
  // Se for usuário parceiro, garante que o primeiro filtro seja o team_id
  console.log("isPartnerFilter no ConversationFilter = ", isPartnerFilter.value)
  if (!isPartnerFilter.value) {
    console.log("isPartnerFilter no ConversationFilter = ", isPartnerFilter.value)
    // Ve se já tem um filtro de team_id
    const existingTeamFilter = filters.value.find(f => f.attributeKey === 'team_id')
    
    if (!existingTeamFilter) {
      // Se não existe, adiciona com o primeiro time do usuario
      const userTeams = teams.value
      const defaultTeam = userTeams.length > 0 ? {id: userTeams[0].id, name: userTeams[0].name } : {}

      filters.value = [{
        attributeKey: 'team_id',
        filterOperator: 'equal_to',
        values: defaultTeam,
        queryOperator: 'and',
      }, ...filters.value]
    } else if (existingTeamFilter && existingTeamFilter !== filters.value[0]) {
      filters.value = [
        existingTeamFilter,
        ...filters.value.filter(f => f.attributeKey !== 'team_id')
      ]
    }
  }

})
const outsideClickHandler = [
  () => emit('close'),
  { ignore: ['#toggleConversationFilterButton'] },
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
    <div v-if="props.isFolderView">
      <div class="border-b border-n-weak pb-6">
        <Input
          v-model="folderNameLocal"
          :label="t('FILTER.FOLDER_LABEL')"
          :placeholder="t('FILTER.INPUT_PLACEHOLDER')"
        />
      </div>
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
