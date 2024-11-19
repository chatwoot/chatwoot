<script setup>
import { useTemplateRef, onBeforeUnmount, onMounted, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import Button from 'next/button/Button.vue';
import ConditionRow from './ConditionRow.vue';
import Dialog from 'next/dialog/Dialog.vue';

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
const filters = defineModel({
  type: Array,
  default: [],
});
const folderNameLocal = ref(props.folderName);

const { t } = useI18n();
const store = useStore();

const resetFilter = () => {
  filters.value = [
    {
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: '',
      query_operator: 'and',
    },
  ];
};

const removeFilter = index => {
  if (filters.value.length === 1) {
    resetFilter();
  } else {
    filters.value.splice(index, 1);
  }
};

const addFilter = () => {
  filters.value.push({
    attribute_key: 'status',
    filter_operator: 'equal_to',
    values: '',
    query_operator: 'and',
  });
};

const conditionsRef = useTemplateRef('conditionsRef');
const dialogRef = useTemplateRef('dialogRef');

function updateSavedCustomViews() {
  const isValid = conditionsRef.value
    .map(condition => condition.validate())
    .every(Boolean);
  if (!isValid) return;

  emit('updateFolder', filters.value, folderNameLocal.value);
}

function validateAndSubmit() {
  const isValid = conditionsRef.value
    .map(condition => condition.validate())
    .every(Boolean);
  if (!isValid) return;

  store.dispatch(
    'setConversationFilters',
    JSON.parse(JSON.stringify(filters.value))
  );
  emit('applyFilter', filters.value);
  useTrack(CONVERSATION_EVENTS.APPLY_FILTER, {
    applied_filters: filters.value.map(filter => ({
      key: filter.attribute_key,
      operator: filter.filter_operator,
      query_operator: filter.query_operator,
    })),
  });
}

const closeModal = () => {
  dialogRef.value.close();
  emit('close');
};

const filterModalHeaderTitle = computed(() => {
  return !props.isFolderView
    ? t('FILTER.TITLE')
    : t('FILTER.EDIT_CUSTOM_FILTER');
});

onMounted(() => dialogRef.value.open());
onBeforeUnmount(closeModal);
useKeyboardEvents({ Escape: { action: closeModal } });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="filterModalHeaderTitle"
    width="3xl"
    @close="() => emit('close')"
  >
    <template #form>
      <div v-if="props.isFolderView" class="">
        <label class="border-b border-n-weak pb-6">
          <div class="text-n-slate-11 text-sm mb-2">
            {{ t('FILTER.FOLDER_LABEL') }}
          </div>
          <input
            v-model="folderNameLocal"
            class="py-1.5 px-3 text-n-slate-12 bg-n-alpha-1 text-sm rounded-lg reset-base w-full"
            :placeholder="t('FILTER.INPUT_PLACEHOLDER')"
          />
        </label>
      </div>
      <ul class="grid gap-4 list-none">
        <template v-for="(filter, index) in filters" :key="filter.id">
          <ConditionRow
            v-if="index === 0"
            ref="conditionsRef"
            v-model:attribute-key="filter.attribute_key"
            v-model:filter-operator="filter.filter_operator"
            v-model:values="filter.values"
            is-first
            @remove="removeFilter(index)"
          />
          <ConditionRow
            v-else
            ref="conditionsRef"
            v-model:attribute-key="filter.attribute_key"
            v-model:filter-operator="filter.filter_operator"
            v-model:query-operator="filters[index - 1].query_operator"
            v-model:values="filter.values"
            @remove="removeFilter(index)"
          />
        </template>
      </ul>
    </template>
    <template #footer>
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
    </template>
  </Dialog>
</template>
