<script setup>
import { ref, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAutomation } from 'dashboard/composables/useAutomation';
import { useEditableAutomation } from 'dashboard/composables/useEditableAutomation';
import AutomationRuleForm from './AutomationRuleForm.vue';
import { AUTOMATION_ACTION_TYPES } from './constants';

const emit = defineEmits(['saveAutomation']);

const START_VALUE = {
  name: null,
  description: null,
  event_name: 'conversation_created',
  execution_delay: null,
  conditions: [
    {
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: '',
      query_operator: 'and',
      custom_attribute_type: '',
    },
  ],
  actions: [
    {
      action_name: 'assign_agent',
      action_params: [],
    },
  ],
};

const store = useStore();
const allCustomAttributes = useMapGetter('attributes/getAttributes');
const formRef = ref(null);

const {
  automation,
  automationTypes,
  onEventChange,
  getConditionDropdownValues,
  appendNewCondition,
  appendNewAction,
  removeFilter,
  removeAction,
  resetAction,
  getActionDropdownValues,
  manifestCustomAttributes,
} = useAutomation(START_VALUE);

const { formatAutomation } = useEditableAutomation();

// `seed` is a partial automation in saved shape (ids, not dropdown options).
const open = (executionDelay = null, seed = null) => {
  manifestCustomAttributes();
  automation.value = seed
    ? formatAutomation(
        { ...structuredClone(START_VALUE), ...seed },
        allCustomAttributes.value,
        automationTypes,
        AUTOMATION_ACTION_TYPES
      )
    : structuredClone(START_VALUE);
  formRef.value?.open(executionDelay);
};
const close = () => formRef.value?.close();

const onSave = (payload, mode) => {
  emit('saveAutomation', payload, mode);
};

onMounted(() => {
  store.dispatch('inboxes/get');
  store.dispatch('agents/get');
  store.dispatch('contacts/get');
  store.dispatch('teams/get');
  store.dispatch('labels/get');
  store.dispatch('campaigns/get');
});

defineExpose({ open, close });
</script>

<template>
  <AutomationRuleForm
    ref="formRef"
    v-model:automation="automation"
    mode="create"
    :automation-types="automationTypes"
    :get-condition-dropdown-values="getConditionDropdownValues"
    :get-action-dropdown-values="getActionDropdownValues"
    :append-new-condition="appendNewCondition"
    :append-new-action="appendNewAction"
    :remove-filter="removeFilter"
    :remove-action="removeAction"
    :reset-action="resetAction"
    :on-event-change="onEventChange"
    @save="onSave"
  />
</template>
