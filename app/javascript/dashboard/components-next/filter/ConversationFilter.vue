<script setup>
import { defineModel, useTemplateRef, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useTrack } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

import Button from 'next/button/Button.vue';
import Dialog from 'next/dialog/Dialog.vue';
import ConditionRow from './ConditionRow.vue';

const emit = defineEmits(['applyFilter', 'close']);
const filters = defineModel({
  type: Array,
  default: [],
});

const { t } = useI18n();
const store = useStore();
const removeFilter = index => {
  filters.value.splice(index, 1);
};

const addFilter = () => {
  filters.value.push({
    attribute_key: 'status',
    filter_operator: 'equal_to',
    values: '',
    query_operator: 'and',
  });
};

const conditionRefs = useTemplateRef('conditions');
const dialogRef = useTemplateRef('dialog');

function validateAndSubmit() {
  const isValid = conditionRefs.value
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

onMounted(() => {
  dialogRef.value.open();
});

onBeforeUnmount(() => {
  dialogRef.value.close();
  emit('close');
});
</script>

<template>
  <Dialog ref="dialog" :title="t('FILTER.TITLE')" @close="emit('close')">
    <template #form>
      <ul class="grid gap-4 list-none">
        <template v-for="(filter, index) in filters" :key="filter.id">
          <ConditionRow
            v-if="index === 0"
            ref="conditions"
            v-model:attribute-key="filter.attribute_key"
            v-model:filter-operator="filter.filter_operator"
            v-model:values="filter.values"
            is-first
            @remove="removeFilter(index)"
          />
          <ConditionRow
            v-else
            ref="conditions"
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
          <Button sm faded slate @click="filters = []">
            {{ t('FILTER.CLEAR_BUTTON_LABEL') }}
          </Button>
          <Button sm solid blue @click="validateAndSubmit">
            {{ t('FILTER.SUBMIT_BUTTON_LABEL') }}
          </Button>
        </div>
      </div>
    </template>
  </Dialog>
</template>
