<script setup>
import { ref, watch } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAutomation } from 'dashboard/composables/useAutomation';
import { useEditableAutomation } from 'dashboard/composables/useEditableAutomation';
import AutomationRuleForm from './AutomationRuleForm.vue';
import { AUTOMATION_ACTION_TYPES } from './constants';

const props = defineProps({
  selectedResponse: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['saveAutomation']);

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
} = useAutomation();

const { formatAutomation } = useEditableAutomation();

const syncAutomationFromSelected = (source = props.selectedResponse) => {
  if (!source?.conditions) return;

  manifestCustomAttributes();
  automation.value = formatAutomation(
    source,
    allCustomAttributes.value,
    automationTypes,
    AUTOMATION_ACTION_TYPES
  );
};

// Format from the rule passed to open(): the prop updates a tick later, so at open() time
// automation still holds the previously selected rule (its execution_delay hydrates the form).
const open = rule => {
  syncAutomationFromSelected(rule);
  formRef.value?.open(rule?.execution_delay);
};
const close = () => formRef.value?.close();

const onSave = (payload, mode) => {
  emit('saveAutomation', payload, mode);
};

watch(() => props.selectedResponse, syncAutomationFromSelected, {
  immediate: true,
});

defineExpose({ open, close });
</script>

<template>
  <AutomationRuleForm
    ref="formRef"
    v-model:automation="automation"
    mode="edit"
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
