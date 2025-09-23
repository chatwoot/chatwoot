<script setup>
import { computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import camelcaseKeys from 'camelcase-keys';
import { getInboxIconByType } from 'dashboard/helper/inbox';

import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import AgentCapacityPolicyForm from 'dashboard/routes/dashboard/settings/assignmentPolicy/pages/components/AgentCapacityPolicyForm.vue';

const BASE_KEY = 'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const uiFlags = useMapGetter('agentCapacityPolicies/getUIFlags');
const usersUiFlags = useMapGetter('agentCapacityPolicies/getUsersUIFlags');
const selectedPolicyById = useMapGetter(
  'agentCapacityPolicies/getAgentCapacityPolicyById'
);
const agentsList = useMapGetter('agents/getAgents');
const labelsList = useMapGetter('labels/getLabels');
const inboxes = useMapGetter('inboxes/getAllInboxes');
const inboxesUiFlags = useMapGetter('inboxes/getUIFlags');

const routeId = computed(() => route.params.id);
const selectedPolicy = computed(() => selectedPolicyById.value(routeId.value));
const selectedPolicyId = computed(() => selectedPolicy.value?.id);

const breadcrumbItems = computed(() => [
  {
    label: t(`${BASE_KEY}.INDEX.HEADER.TITLE`),
    routeName: 'agent_capacity_policy_index',
  },
  { label: t(`${BASE_KEY}.EDIT.HEADER.TITLE`) },
]);

const buildList = items =>
  items?.map(({ name, title, id, email, avatarUrl, thumbnail, color }) => ({
    name: name || title,
    id,
    email,
    avatarUrl: avatarUrl || thumbnail,
    color,
  })) || [];

const policyUsers = computed(() => buildList(selectedPolicy.value?.users));

const allAgents = computed(() =>
  buildList(camelcaseKeys(agentsList.value)).filter(
    agent => !policyUsers.value?.some(user => user.id === agent.id)
  )
);

const allLabels = computed(() => buildList(labelsList.value));

const allInboxes = computed(
  () =>
    inboxes.value
      ?.slice()
      .sort((a, b) => a.name.localeCompare(b.name))
      .map(({ name, id, email, phoneNumber, channelType, medium }) => ({
        name,
        id,
        email,
        phoneNumber,
        icon: getInboxIconByType(channelType, medium, 'line'),
      })) || []
);

const formData = computed(() => ({
  name: selectedPolicy.value?.name || '',
  description: selectedPolicy.value?.description || '',
  exclusionRules: {
    excludedLabels: [
      ...(selectedPolicy.value?.exclusionRules?.excludedLabels || []),
    ],
    excludeOlderThanHours:
      selectedPolicy.value?.exclusionRules?.excludeOlderThanHours || 10,
  },
  inboxCapacityLimits:
    selectedPolicy.value?.inboxCapacityLimits?.map(limit => ({
      ...limit,
    })) || [],
}));

const handleBreadcrumbClick = ({ routeName }) =>
  router.push({ name: routeName });

const handleDeleteUser = agentId => {
  store.dispatch('agentCapacityPolicies/removeUser', {
    policyId: selectedPolicyId.value,
    userId: agentId,
  });
};

const handleAddUser = agent => {
  store.dispatch('agentCapacityPolicies/addUser', {
    policyId: selectedPolicyId.value,
    userData: { id: agent.id, capacity: 20 },
  });
};

const handleDeleteInboxLimit = limitId => {
  store.dispatch('agentCapacityPolicies/deleteInboxLimit', {
    policyId: selectedPolicyId.value,
    limitId,
  });
};

const handleAddInboxLimit = limit => {
  store.dispatch('agentCapacityPolicies/createInboxLimit', {
    policyId: selectedPolicyId.value,
    limitData: {
      inboxId: limit.inboxId,
      conversationLimit: limit.conversationLimit,
    },
  });
};

const handleLimitChange = limit => {
  store.dispatch('agentCapacityPolicies/updateInboxLimit', {
    policyId: selectedPolicyId.value,
    limitId: limit.id,
    limitData: { conversationLimit: limit.conversationLimit },
  });
};

const handleSubmit = async formState => {
  try {
    await store.dispatch('agentCapacityPolicies/update', {
      id: selectedPolicyId.value,
      ...formState,
    });

    useAlert(t(`${BASE_KEY}.EDIT.API.SUCCESS_MESSAGE`));
  } catch {
    useAlert(t(`${BASE_KEY}.EDIT.API.ERROR_MESSAGE`));
  }
};

const fetchPolicyData = async () => {
  if (!routeId.value) return;

  // Fetch policy if not available
  if (!selectedPolicyId.value)
    await store.dispatch('agentCapacityPolicies/show', routeId.value);

  await store.dispatch('agentCapacityPolicies/getUsers', Number(routeId.value));
};

watch(routeId, fetchPolicyData, { immediate: true });
onMounted(() => store.dispatch('agents/get'));
</script>

<template>
  <SettingsLayout :is-loading="uiFlags.isFetchingItem" class="xl:px-44">
    <template #header>
      <div class="flex items-center gap-2 w-full justify-between">
        <Breadcrumb :items="breadcrumbItems" @click="handleBreadcrumbClick" />
      </div>
    </template>

    <template #body>
      <AgentCapacityPolicyForm
        :key="routeId"
        mode="EDIT"
        :initial-data="formData"
        :policy-users="policyUsers"
        :agent-list="allAgents"
        :label-list="allLabels"
        :inbox-list="allInboxes"
        show-user-section
        show-inbox-limit-section
        :is-loading="uiFlags.isUpdating"
        :is-users-loading="usersUiFlags.isFetching"
        :is-inboxes-loading="inboxesUiFlags.isFetching"
        @submit="handleSubmit"
        @add-user="handleAddUser"
        @delete-user="handleDeleteUser"
        @add-inbox-limit="handleAddInboxLimit"
        @update-inbox-limit="handleLimitChange"
        @delete-inbox-limit="handleDeleteInboxLimit"
      />
    </template>
  </SettingsLayout>
</template>
