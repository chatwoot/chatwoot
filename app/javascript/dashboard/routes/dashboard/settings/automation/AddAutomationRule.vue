<script setup>

import { ref, onMounted } from 'vue';

import { useStore } from 'dashboard/composables/store';

import { useAutomation } from 'dashboard/composables/useAutomation';

import AutomationRuleForm from './AutomationRuleForm.vue';

import { DEFAULT_DELAY_MINUTES } from './constants';



const emit = defineEmits(['saveAutomation']);



const START_VALUE_EVENT = {

  name: null,

  description: null,

  event_name: 'conversation_created',

  schedule: {},

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



const START_VALUE_TIME = {

  name: null,

  description: null,

  event_name: 'time_triggered',

  schedule: { kind: 'hours_since_last_outgoing', hours: 24 },

  execution_delay: null,

  conditions: [],

  actions: [

    {

      action_name: 'send_message',

      action_params: [],

    },

  ],

};



const store = useStore();

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

} = useAutomation(START_VALUE_EVENT);



const open = async (modeOrDelay = null) => {

  if (modeOrDelay === 'time' || modeOrDelay === 'event') {

    automation.value = structuredClone(

      modeOrDelay === 'time' ? START_VALUE_TIME : START_VALUE_EVENT

    );

    await Promise.all([

      store.dispatch('attributes/get'),

      store.dispatch('macros/get'),

      store.dispatch('flows/get'),

    ]);

    manifestCustomAttributes();

    formRef.value?.open(null);

    return;

  }



  automation.value = structuredClone(START_VALUE_EVENT);

  manifestCustomAttributes();

  formRef.value?.open(

    typeof modeOrDelay === 'number' ? modeOrDelay : null

  );

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

  store.dispatch('attributes/get');

  store.dispatch('macros/get');

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


