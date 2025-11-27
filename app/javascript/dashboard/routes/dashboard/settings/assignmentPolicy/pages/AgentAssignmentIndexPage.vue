<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';

import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import AssignmentPolicyCard from 'dashboard/components-next/AssignmentPolicy/AssignmentPolicyCard/AssignmentPolicyCard.vue';
import ConfirmDeletePolicyDialog from './components/ConfirmDeletePolicyDialog.vue';

const store = useStore();
const { t } = useI18n();
const router = useRouter();

const agentAssignmentsPolicies = useMapGetter(
  'assignmentPolicies/getAssignmentPolicies'
);
const uiFlags = useMapGetter('assignmentPolicies/getUIFlags');
const inboxUiFlags = useMapGetter('assignmentPolicies/getInboxUiFlags');

const confirmDeletePolicyDialogRef = ref(null);

const breadcrumbItems = computed(() => {
  const items = [
    {
      label: t('ASSIGNMENT_POLICY.INDEX.HEADER.TITLE'),
      routeName: 'assignment_policy_index',
    },
    {
      label: t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.INDEX.HEADER.TITLE'),
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
    name: 'agent_assignment_policy_create',
  });
};

const onClickEditPolicy = id => {
  router.push({
    name: 'agent_assignment_policy_edit',
    params: {
      id,
    },
  });
};

const handleFetchInboxes = id => {
  if (inboxUiFlags.value.isFetching) return;
  store.dispatch('assignmentPolicies/getInboxes', id);
};

const handleDelete = id => {
  confirmDeletePolicyDialogRef.value.openDialog(id);
};

const handleDeletePolicy = async policyId => {
  try {
    await store.dispatch('assignmentPolicies/delete', policyId);
    useAlert(
      t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.DELETE_POLICY.SUCCESS_MESSAGE'
      )
    );
    confirmDeletePolicyDialogRef.value.closeDialog();
  } catch (error) {
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.DELETE_POLICY.ERROR_MESSAGE')
    );
  }
};

onMounted(() => {
  store.dispatch('assignmentPolicies/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :no-records-found="agentAssignmentsPolicies.length === 0"
    :no-records-message="
      $t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.INDEX.NO_RECORDS_FOUND')
    "
  >
    <template #header>
      <div class="flex items-center gap-2 w-full justify-between">
        <Breadcrumb :items="breadcrumbItems" @click="handleBreadcrumbClick" />
        <Button icon="i-lucide-plus" md @click="onClickCreatePolicy">
          {{
            $t(
              'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.INDEX.HEADER.CREATE_POLICY'
            )
          }}
        </Button>
      </div>
    </template>
    <template #body>
      <div class="flex flex-col gap-4 pt-8">
        <AssignmentPolicyCard
          v-for="policy in agentAssignmentsPolicies"
          :key="policy.id"
          v-bind="policy"
          :is-fetching-inboxes="inboxUiFlags.isFetching"
          @fetch-inboxes="handleFetchInboxes"
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
