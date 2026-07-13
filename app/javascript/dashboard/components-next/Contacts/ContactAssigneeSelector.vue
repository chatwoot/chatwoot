<script setup>
import { computed, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useFunctionGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update']);

const { t } = useI18n();
const store = useStore();

const isUpdating = ref(false);

const currentUser = computed(() => store.getters.getCurrentUser);
const isAdmin = computed(() => currentUser.value?.role === 'administrator');
const currentUserId = computed(() => currentUser.value?.id);

const agents = computed(() => store.getters['agents/getAgents'] || []);

const contactId = computed(() => props.contact?.id);
const resolvedContact = useFunctionGetter('contacts/getContactById', contactId);

const assignedAgentId = computed(
  () =>
    resolvedContact.value?.assignedAgentId ??
    resolvedContact.value?.assigned_agent_id
);
const assignedAgent = computed(
  () =>
    resolvedContact.value?.assignedAgent ??
    resolvedContact.value?.assigned_agent
);

const isAssignedToMe = computed(
  () =>
    assignedAgentId.value &&
    Number(assignedAgentId.value) === Number(currentUserId.value)
);

const isUnassigned = computed(() => !assignedAgentId.value);

const selectedAgent = computed(() => {
  if (!assignedAgentId.value) return null;
  return (
    agents.value.find(agent => agent.id === Number(assignedAgentId.value)) ||
    assignedAgent.value ||
    null
  );
});

const agentsList = computed(() => {
  const noneOption = {
    id: 0,
    name: t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.NONE') || 'None',
    role: 'agent',
    account_id: 0,
    email: '',
    confirmed: true,
  };
  return [noneOption, ...agents.value];
});

const fetchAgents = () => {
  store.dispatch('agents/get');
};

watch(
  () => store.getters.getCurrentAccountId,
  () => fetchAgents(),
  { immediate: true }
);

const updateAssignedAgent = async agentId => {
  if (isUpdating.value) return;

  isUpdating.value = true;
  try {
    await store.dispatch('contacts/update', {
      id: props.contact.id,
      assignedAgentId: agentId,
    });
    emit('update', { assignedAgentId: agentId });
    useAlert(t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.UPDATE_SUCCESS'));
  } catch {
    useAlert(t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.UPDATE_ERROR'));
  } finally {
    isUpdating.value = false;
  }
};

const handleSelect = async agent => {
  if (!isAdmin.value) return;

  const selectedAgentId = agent?.id ? Number(agent.id) : null;
  if (selectedAgentId === (assignedAgentId.value || null)) return;

  await updateAssignedAgent(selectedAgentId);
};

const handleSelfAssign = () => {
  if (!currentUserId.value) return;
  updateAssignedAgent(currentUserId.value);
};

const handleSelfUnassign = () => {
  updateAssignedAgent(null);
};
</script>

<template>
  <div class="w-full">
    <label class="block mb-1.5 text-sm font-medium text-n-slate-11">
      {{ t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.LABEL') }}
    </label>

    <!-- Admin view: full dropdown -->
    <template v-if="isAdmin">
      <MultiselectDropdown
        :compact="false"
        :disabled="disabled || isUpdating"
        :options="agentsList"
        :selected-item="selectedAgent"
        :multiselector-title="t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
        :multiselector-placeholder="t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :no-search-result="
          t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
        "
        :input-placeholder="
          t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
        "
        @select="handleSelect"
      />
    </template>

    <!-- Agent view: read-only text + self-assign/unassign buttons -->
    <template v-else>
      <div class="flex flex-col gap-2">
        <div class="text-sm text-n-slate-12">
          <span v-if="isUnassigned" class="text-n-slate-10">
            {{ t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.NONE') }}
          </span>
          <span v-else-if="isAssignedToMe">
            {{ assignedAgent?.name || assignedAgent?.available_name || '' }}
          </span>
          <span v-else>
            {{
              t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.ASSIGNED_TO_OTHER', {
                agentName:
                  assignedAgent?.name || assignedAgent?.available_name || '',
              })
            }}
          </span>
        </div>

        <NextButton
          v-if="isUnassigned"
          size="sm"
          slate
          faded
          :is-loading="isUpdating"
          :disabled="disabled || isUpdating || !currentUserId"
          :label="t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.SELF_ASSIGN')"
          @click="handleSelfAssign"
        />
        <NextButton
          v-else-if="isAssignedToMe"
          size="sm"
          slate
          faded
          :is-loading="isUpdating"
          :disabled="disabled || isUpdating"
          :label="t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.SELF_UNASSIGN')"
          @click="handleSelfUnassign"
        />
      </div>
    </template>
  </div>
</template>
