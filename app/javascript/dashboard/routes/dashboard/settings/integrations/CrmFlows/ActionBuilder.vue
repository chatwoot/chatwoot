<script setup>
import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';

const props = defineProps({
  modelValue: { type: Array, default: () => [] },
});
const emit = defineEmits(['update:modelValue']);

const getters = useStoreGetters();

const CRM_ACTION_OPTIONS = [
  { value: 'create_lead', label: 'CRM_FLOWS.ACTIONS_BUILDER.CREATE_LEAD' },
  {
    value: 'create_contact',
    label: 'CRM_FLOWS.ACTIONS_BUILDER.CREATE_CONTACT',
  },
  {
    value: 'create_opportunity',
    label: 'CRM_FLOWS.ACTIONS_BUILDER.CREATE_OPPORTUNITY',
  },
  { value: 'create_task', label: 'CRM_FLOWS.ACTIONS_BUILDER.CREATE_TASK' },
  { value: 'create_call', label: 'CRM_FLOWS.ACTIONS_BUILDER.CREATE_CALL' },
  { value: 'create_event', label: 'CRM_FLOWS.ACTIONS_BUILDER.CREATE_EVENT' },
  { value: 'add_crm_tag', label: 'CRM_FLOWS.ACTIONS_BUILDER.ADD_CRM_TAG' },
  { value: 'add_note', label: 'CRM_FLOWS.ACTIONS_BUILDER.ADD_NOTE' },
];

const DESK_ACTION_OPTIONS = [
  {
    value: 'create_ticket',
    label: 'CRM_FLOWS.ACTIONS_BUILDER.CREATE_TICKET',
  },
];

const CHATWOOT_ACTION_OPTIONS = [
  {
    value: 'assign_chatwoot_agent',
    label: 'CRM_FLOWS.ACTIONS_BUILDER.ASSIGN_AGENT',
  },
  { value: 'add_chatwoot_label', label: 'CRM_FLOWS.ACTIONS_BUILDER.ADD_LABEL' },
];

// Qué CRMs soportan qué acciones
const CRM_SUPPORT = {
  salesforce: [
    'create_lead',
    'create_contact',
    'create_opportunity',
    'create_task',
    'create_event',
    'add_note',
  ],
  zoho: [
    'create_lead',
    'create_contact',
    'create_task',
    'create_call',
    'create_event',
    'add_crm_tag',
    'add_note',
  ],
  hubspot: [
    'create_lead',
    'create_contact',
    'create_opportunity',
    'create_task',
    'create_event',
    'add_note',
  ],
};

const connectedCrms = computed(() => {
  const integrations = getters['integrations/getAppIntegrations'].value || [];
  return integrations
    .filter(i => ['salesforce', 'zoho', 'hubspot'].includes(i.id) && i.enabled)
    .map(i => i.id);
});

const isDeskConnected = computed(() => {
  const integrations = getters['integrations/getAppIntegrations'].value || [];
  const zoho = integrations.find(i => i.id === 'zoho' && i.enabled);
  if (!zoho) return false;
  return zoho.hooks?.some(h => h.settings?.desk_soid);
});

const actions = computed(() => props.modelValue);

function update(newActions) {
  emit('update:modelValue', newActions);
}

function addAction() {
  update([
    ...actions.value,
    {
      order: actions.value.length + 1,
      action: 'create_lead',
      type: 'crm',
      params: {},
    },
  ]);
}

function removeAction(index) {
  update(actions.value.filter((_, i) => i !== index));
}

function changeAction(index, newAction) {
  const updated = actions.value.map((a, i) => {
    if (i !== index) return a;
    const isCrm = CRM_ACTION_OPTIONS.some(o => o.value === newAction);
    const isDesk = DESK_ACTION_OPTIONS.some(o => o.value === newAction);
    let type = 'chatwoot';
    if (isCrm) type = 'crm';
    if (isDesk) type = 'desk';
    return {
      ...a,
      action: newAction,
      type,
      params: {},
    };
  });
  update(updated);
}

function changeParam(index, key, value) {
  const updated = actions.value.map((a, i) => {
    if (i !== index) return a;
    return { ...a, params: { ...a.params, [key]: value } };
  });
  update(updated);
}

function isCrmAction(actionName) {
  return CRM_ACTION_OPTIONS.some(o => o.value === actionName);
}

function isDeskAction(actionName) {
  return DESK_ACTION_OPTIONS.some(o => o.value === actionName);
}

function crmSupports(crm, actionName) {
  return (CRM_SUPPORT[crm] || []).includes(actionName);
}

const agents = computed(() => getters['agents/getAgents'].value || []);
</script>

<template>
  <div class="flex flex-col gap-3">
    <h4 class="text-sm font-semibold text-n-slate-11">
      {{ $t('CRM_FLOWS.ACTIONS_BUILDER.TITLE') }}
    </h4>

    <div
      v-for="(action, index) in actions"
      :key="index"
      class="border border-n-weak rounded-lg p-3 flex flex-col gap-2"
    >
      <!-- Número + selector de acción -->
      <div class="flex items-center gap-2">
        <span class="text-xs font-bold text-n-slate-9 w-5 text-center">{{
          index + 1
        }}</span>
        <select
          :value="action.action"
          class="flex-1 text-sm border border-n-weak rounded px-2 py-1.5 bg-n-solid-1 text-n-slate-12"
          @change="changeAction(index, $event.target.value)"
        >
          <optgroup :label="$t('CRM_FLOWS.ACTIONS_BUILDER.CRM_ACTIONS')">
            <option
              v-for="opt in CRM_ACTION_OPTIONS"
              :key="opt.value"
              :value="opt.value"
            >
              {{ $t(opt.label) }}
            </option>
          </optgroup>
          <optgroup
            v-if="isDeskConnected"
            :label="$t('CRM_FLOWS.ACTIONS_BUILDER.DESK_ACTIONS')"
          >
            <option
              v-for="opt in DESK_ACTION_OPTIONS"
              :key="opt.value"
              :value="opt.value"
            >
              {{ $t(opt.label) }}
            </option>
          </optgroup>
          <optgroup :label="$t('CRM_FLOWS.ACTIONS_BUILDER.CHATWOOT_ACTIONS')">
            <option
              v-for="opt in CHATWOOT_ACTION_OPTIONS"
              :key="opt.value"
              :value="opt.value"
            >
              {{ $t(opt.label) }}
            </option>
          </optgroup>
        </select>
        <button
          type="button"
          class="text-n-slate-9 hover:text-red-500 transition-colors p-1"
          @click="removeAction(index)"
        >
          <i class="i-lucide-x w-4 h-4" />
        </button>
      </div>

      <!-- Parámetros según tipo de acción -->
      <div v-if="action.action === 'add_crm_tag'" class="ml-7">
        <input
          :value="action.params.tag_name"
          type="text"
          :placeholder="$t('CRM_FLOWS.ACTIONS_BUILDER.PARAMS.TAG_NAME')"
          class="w-full text-sm border border-n-weak rounded px-2 py-1.5 bg-n-solid-1 text-n-slate-12"
          @input="changeParam(index, 'tag_name', $event.target.value)"
        />
      </div>

      <div v-else-if="action.action === 'assign_chatwoot_agent'" class="ml-7">
        <select
          :value="action.params.agent_id"
          class="w-full text-sm border border-n-weak rounded px-2 py-1.5 bg-n-solid-1 text-n-slate-12"
          @change="changeParam(index, 'agent_id', Number($event.target.value))"
        >
          <option value="">
            {{ $t('CRM_FLOWS.ACTIONS_BUILDER.PARAMS.AGENT') }}
          </option>
          <option v-for="agent in agents" :key="agent.id" :value="agent.id">
            {{ agent.name }}
          </option>
        </select>
      </div>

      <div v-else-if="action.action === 'add_chatwoot_label'" class="ml-7">
        <input
          :value="action.params.label"
          type="text"
          :placeholder="$t('CRM_FLOWS.ACTIONS_BUILDER.PARAMS.LABEL')"
          class="w-full text-sm border border-n-weak rounded px-2 py-1.5 bg-n-solid-1 text-n-slate-12"
          @input="changeParam(index, 'label', $event.target.value)"
        />
      </div>

      <div
        v-else-if="action.action === 'add_note'"
        class="ml-7 flex flex-col gap-1.5"
      >
        <input
          :value="action.params.note_title"
          type="text"
          :placeholder="$t('CRM_FLOWS.ACTIONS_BUILDER.PARAMS.TITLE')"
          class="w-full text-sm border border-n-weak rounded px-2 py-1.5 bg-n-solid-1 text-n-slate-12"
          @input="changeParam(index, 'note_title', $event.target.value)"
        />
        <input
          :value="action.params.note_text"
          type="text"
          :placeholder="$t('CRM_FLOWS.ACTIONS_BUILDER.PARAMS.CONTENT')"
          class="w-full text-sm border border-n-weak rounded px-2 py-1.5 bg-n-solid-1 text-n-slate-12"
          @input="changeParam(index, 'note_text', $event.target.value)"
        />
      </div>

      <div v-else-if="action.action === 'create_task'" class="ml-7">
        <input
          :value="action.params.subject"
          type="text"
          :placeholder="$t('CRM_FLOWS.ACTIONS_BUILDER.PARAMS.SUBJECT')"
          class="w-full text-sm border border-n-weak rounded px-2 py-1.5 bg-n-solid-1 text-n-slate-12"
          @input="changeParam(index, 'subject', $event.target.value)"
        />
      </div>

      <div
        v-else-if="action.action === 'create_call'"
        class="ml-7 flex flex-col gap-2"
      >
        <input
          :value="action.params.subject"
          type="text"
          :placeholder="$t('CRM_FLOWS.ACTIONS_BUILDER.PARAMS.SUBJECT')"
          class="w-full text-sm border border-n-weak rounded px-2 py-1.5 bg-n-solid-1 text-n-slate-12"
          @input="changeParam(index, 'subject', $event.target.value)"
        />
        <input
          :value="action.params.description"
          type="text"
          :placeholder="$t('CRM_FLOWS.ACTIONS_BUILDER.PARAMS.DESCRIPTION')"
          class="w-full text-sm border border-n-weak rounded px-2 py-1.5 bg-n-solid-1 text-n-slate-12"
          @input="changeParam(index, 'description', $event.target.value)"
        />
      </div>

      <!-- Indicadores de compatibilidad Desk -->
      <div v-if="isDeskAction(action.action)" class="ml-7 flex gap-2">
        <span
          :class="isDeskConnected ? 'text-green-600' : 'text-n-slate-9'"
          class="text-xs flex items-center gap-1"
        >
          <span
            :class="isDeskConnected ? 'bg-green-500' : 'bg-n-slate-4'"
            class="inline-block w-1.5 h-1.5 rounded-full"
          />
          Zoho Desk
        </span>
      </div>

      <!-- Indicadores de compatibilidad CRM -->
      <div v-if="isCrmAction(action.action)" class="ml-7 flex gap-2">
        <span
          v-for="crm in connectedCrms"
          :key="crm"
          :class="
            crmSupports(crm, action.action)
              ? 'text-green-600'
              : 'text-n-slate-9'
          "
          class="text-xs flex items-center gap-1"
        >
          <span
            :class="
              crmSupports(crm, action.action) ? 'bg-green-500' : 'bg-n-slate-4'
            "
            class="inline-block w-1.5 h-1.5 rounded-full"
          />
          {{ crm.charAt(0).toUpperCase() + crm.slice(1) }}
        </span>
      </div>
    </div>

    <button
      type="button"
      class="text-sm text-blue-600 hover:text-blue-700 font-medium text-left"
      @click="addAction"
    >
      {{ $t('CRM_FLOWS.ACTIONS_BUILDER.ADD_ACTION') }}
    </button>
  </div>
</template>
