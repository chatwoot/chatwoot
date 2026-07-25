<script setup>
import { computed, ref, watch, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useFunctionGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import OutlinedSelectField from 'dashboard/components-next/CustomAttributes/OutlinedSelectField.vue';
import OutlinedAttributeField from 'dashboard/components-next/CustomAttributes/OutlinedAttributeField.vue';
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

const assignedAgentName = computed(
  () => assignedAgent.value?.name || assignedAgent.value?.available_name || ''
);

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

onMounted(fetchAgents);

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
  // Treat id 0 as unassign
  const nextId = selectedAgentId === 0 ? null : selectedAgentId;
  if (nextId === (assignedAgentId.value || null)) return;

  await updateAssignedAgent(nextId);
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
  <!-- Admin: outlined select (DropdownMenu) -->
  <OutlinedSelectField
    v-if="isAdmin"
    :label="t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.LABEL')"
    :options="agentsList"
    :selected-item="selectedAgent"
    :placeholder="t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.NONE')"
    :disabled="disabled || isUpdating"
    has-thumbnail
    :class="{
      'ring-2 ring-n-brand/70 animate-pulse rounded-lg': isUnassigned,
    }"
    @select="handleSelect"
  />

  <!-- Agent: self-assign / view -->
  <OutlinedAttributeField
    v-else
    :label="t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.LABEL')"
    filled
    :class="{
      'ring-2 ring-n-brand/70 animate-pulse rounded-lg': isUnassigned,
    }"
  >
    <NextButton
      v-if="isUnassigned"
      class="w-full !h-8 !outline-none !shadow-none !bg-transparent"
      size="sm"
      slate
      ghost
      :is-loading="isUpdating"
      :disabled="disabled || isUpdating || !currentUserId"
      :label="t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.SELF_ASSIGN')"
      @click="handleSelfAssign"
    />

    <div
      v-else-if="isAssignedToMe"
      class="flex items-center gap-1 min-h-8 w-full"
    >
      <span
        class="flex-1 min-w-0 text-sm text-n-slate-12 truncate"
        :title="assignedAgentName"
      >
        {{ assignedAgentName }}
      </span>
      <NextButton
        v-tooltip.left="t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.SELF_UNASSIGN')"
        :aria-label="t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.SELF_UNASSIGN')"
        icon="i-lucide-user-round-x"
        ghost
        slate
        xs
        :is-loading="isUpdating"
        :disabled="disabled || isUpdating"
        @click="handleSelfUnassign"
      />
    </div>

    <div v-else class="flex items-center min-h-8 w-full">
      <span class="text-sm text-n-slate-11 truncate">
        {{
          t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.ASSIGNED_TO_OTHER', {
            agentName: assignedAgentName,
          })
        }}
      </span>
    </div>
  </OutlinedAttributeField>
</template>
