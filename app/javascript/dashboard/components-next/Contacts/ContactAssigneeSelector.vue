<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';

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

const agents = computed(() => store.getters['agents/getAgents'] || []);

const assignedAgentId = computed(() => props.contact?.assignedAgentId);

const selectedAgent = computed(() => {
  if (!assignedAgentId.value) return null;
  return (
    agents.value.find(agent => agent.id === Number(assignedAgentId.value)) ||
    null
  );
});

const agentsList = computed(() => {
  const noneOption = {
    id: 0,
    name: t('AGENT_MGMT.MULTI_SELECTOR.LIST.NONE') || 'None',
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

onMounted(fetchAgents);

watch(
  () => store.getters.getCurrentAccountId,
  () => fetchAgents(),
  { immediate: true }
);

const handleSelect = async agent => {
  if (!isAdmin.value) return;

  const selectedAgentId = agent?.id ? Number(agent.id) : null;
  if (selectedAgentId === (props.contact?.assignedAgentId || null)) return;

  isUpdating.value = true;
  try {
    await store.dispatch('contacts/update', {
      id: props.contact.id,
      assignedAgentId: selectedAgentId,
    });
    emit('update', { assignedAgentId: selectedAgentId });
    useAlert(t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.UPDATE_SUCCESS'));
  } catch {
    useAlert(t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.UPDATE_ERROR'));
  } finally {
    isUpdating.value = false;
  }
};
</script>

<template>
  <div class="w-full">
    <label class="block mb-1.5 text-sm font-medium text-n-slate-11">
      {{ t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.LABEL') }}
    </label>
    <MultiselectDropdown
      :compact="false"
      :disabled="disabled || isUpdating || !isAdmin"
      :options="agentsList"
      :selected-item="selectedAgent"
      :multiselector-title="t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
      :multiselector-placeholder="t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
      :no-search-result="t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')"
      :input-placeholder="
        t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
      "
      @select="handleSelect"
    />
    <p v-if="!isAdmin" class="mt-1 text-xs text-n-slate-10">
      {{ t('CONTACTS_LAYOUT.DETAILS.ASSIGNEE.ADMIN_ONLY') }}
    </p>
  </div>
</template>
