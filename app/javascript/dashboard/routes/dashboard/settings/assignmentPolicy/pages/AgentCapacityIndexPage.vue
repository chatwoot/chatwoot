<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';

import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import AgentCapacityPolicyCard from 'dashboard/components-next/AssignmentPolicy/AgentCapacityPolicyCard/AgentCapacityPolicyCard.vue';
import ConfirmDeletePolicyDialog from './components/ConfirmDeletePolicyDialog.vue';

const store = useStore();
const { t } = useI18n();
const router = useRouter();

const agentCapacityPolicies = useMapGetter(
  'agentCapacityPolicies/getAgentCapacityPolicies'
);
const uiFlags = useMapGetter('agentCapacityPolicies/getUIFlags');
const usersUiFlags = useMapGetter('agentCapacityPolicies/getUsersUIFlags');

const confirmDeletePolicyDialogRef = ref(null);

const breadcrumbItems = computed(() => {
  const items = [
    {
      label: t('ASSIGNMENT_POLICY.INDEX.HEADER.TITLE'),
      routeName: 'assignment_policy_index',
    },
    {
      label: t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.HEADER.TITLE'),
    },
  ];
  return items;
});

const handleBreadcrumbClick = item => {
  router.push({
    name: item.routeName,
  });
};

const onClickCreatePolicy = () => {
  router.push({
    name: 'agent_capacity_policy_create',
  });
};

const onClickEditPolicy = id => {
  router.push({
    name: 'agent_capacity_policy_edit',
    params: {
      id,
    },
  });
};

const handleFetchUsers = id => {
  if (usersUiFlags.value.isFetching) return;
  store.dispatch('agentCapacityPolicies/getUsers', id);
};

const handleDelete = id => {
  confirmDeletePolicyDialogRef.value.openDialog(id);
};

const handleDeletePolicy = async policyId => {
  try {
    await store.dispatch('agentCapacityPolicies/delete', policyId);
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.DELETE_POLICY.SUCCESS_MESSAGE')
    );
    confirmDeletePolicyDialogRef.value.closeDialog();
  } catch (error) {
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.DELETE_POLICY.ERROR_MESSAGE')
    );
  }
};

onMounted(() => {
  store.dispatch('agentCapacityPolicies/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :no-records-found="agentCapacityPolicies.length === 0"
    :no-records-message="
      $t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.NO_RECORDS_FOUND')
    "
  >
    <template #header>
      <div class="flex items-center gap-2 w-full justify-between min-h-10">
        <Breadcrumb :items="breadcrumbItems" @click="handleBreadcrumbClick" />
        <Button icon="i-lucide-plus" md @click="onClickCreatePolicy">
          {{
            $t(
              'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.HEADER.CREATE_POLICY'
            )
          }}
        </Button>
      </div>
    </template>
    <template #body>
      <div class="flex flex-col gap-4 pt-4">
        <AgentCapacityPolicyCard
          v-for="policy in agentCapacityPolicies"
          :key="policy.id"
          v-bind="policy"
          :is-fetching-users="usersUiFlags.isFetching"
          @fetch-users="handleFetchUsers"
          @edit="onClickEditPolicy"
          @delete="handleDelete"
        />
      </div>
    </template>
    <ConfirmDeletePolicyDialog
      ref="confirmDeletePolicyDialogRef"
      @delete="handleDeletePolicy"
    />
  </SettingsLayout>
</template>
