<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import {
  ROUND_ROBIN,
  EARLIEST_CREATED,
} from 'dashboard/routes/dashboard/settings/assignmentPolicy/constants';

import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import AssignmentPolicyForm from 'dashboard/routes/dashboard/settings/assignmentPolicy/pages/components/AgentAssignmentPolicyForm.vue';
import ConfirmInboxDialog from 'dashboard/routes/dashboard/settings/assignmentPolicy/pages/components/ConfirmInboxDialog.vue';
import InboxLinkDialog from 'dashboard/routes/dashboard/settings/assignmentPolicy/pages/components/InboxLinkDialog.vue';

const BASE_KEY = 'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();

const uiFlags = useMapGetter('assignmentPolicies/getUIFlags');
const inboxes = useMapGetter('inboxes/getAllInboxes');
const inboxUiFlags = useMapGetter('assignmentPolicies/getInboxUiFlags');
const selectedPolicyById = useMapGetter(
  'assignmentPolicies/getAssignmentPolicyById'
);

const routeId = computed(() => route.params.id);
const selectedPolicy = computed(() => selectedPolicyById.value(routeId.value));

const confirmInboxDialogRef = ref(null);
// Store the policy linked to the inbox when adding a new inbox
const inboxLinkedPolicy = ref(null);

// Inbox linking prompt from create flow
const inboxIdFromQuery = computed(() => {
  const id = route.query.inboxId;
  return id ? Number(id) : null;
});

const suggestedInbox = computed(() => {
  if (!inboxIdFromQuery.value || !inboxes.value) return null;
  return inboxes.value.find(inbox => inbox.id === inboxIdFromQuery.value);
});

const isLinkingInbox = ref(false);

const dismissInboxLinkPrompt = () => {
  router.replace({
    name: route.name,
    params: route.params,
    query: {},
  });
};

const breadcrumbItems = computed(() => {
  if (inboxIdFromQuery.value) {
    return [
      {
        label: t('INBOX_MGMT.SETTINGS'),
        routeName: 'settings_inbox_show',
        params: { inboxId: inboxIdFromQuery.value },
      },
      { label: t(`${BASE_KEY}.EDIT.HEADER.TITLE`) },
    ];
  }
  return [
    {
      label: t(`${BASE_KEY}.INDEX.HEADER.TITLE`),
      routeName: 'agent_assignment_policy_index',
    },
    { label: t(`${BASE_KEY}.EDIT.HEADER.TITLE`) },
  ];
});

const buildInboxList = allInboxes =>
  allInboxes?.map(({ name, id, email, phoneNumber, channelType, medium }) => ({
    name,
    id,
    email,
    phoneNumber,
    icon: getInboxIconByType(channelType, medium, 'line'),
  })) || [];

const policyInboxes = computed(() =>
  buildInboxList(selectedPolicy.value?.inboxes)
);

const inboxList = computed(() =>
  buildInboxList(
    inboxes.value?.slice().sort((a, b) => a.name.localeCompare(b.name))
  )
);

const formData = computed(() => ({
  name: selectedPolicy.value?.name || '',
  description: selectedPolicy.value?.description || '',
  enabled: true,
  assignmentOrder: selectedPolicy.value?.assignmentOrder || ROUND_ROBIN,
  conversationPriority:
    selectedPolicy.value?.conversationPriority || EARLIEST_CREATED,
  fairDistributionLimit: selectedPolicy.value?.fairDistributionLimit || 100,
  fairDistributionWindow: selectedPolicy.value?.fairDistributionWindow || 3600,
}));

const handleDeleteInbox = async inboxId => {
  try {
    await store.dispatch('assignmentPolicies/removeInboxPolicy', {
      policyId: selectedPolicy.value?.id,
      inboxId,
    });
    useAlert(t(`${BASE_KEY}.EDIT.INBOX_API.REMOVE.SUCCESS_MESSAGE`));
  } catch {
    useAlert(t(`${BASE_KEY}.EDIT.INBOX_API.REMOVE.ERROR_MESSAGE`));
  }
};

const handleBreadcrumbClick = ({ routeName, params }) => {
  if (params) {
    const accountId = route.params.accountId;
    const inboxId = params.inboxId;
    // Navigate using explicit path to ensure tab parameter is included
    router.push(
      `/app/accounts/${accountId}/settings/inboxes/${inboxId}/collaborators`
    );
  } else {
    router.push({ name: routeName });
  }
};

const handleNavigateToInbox = inbox => {
  router.push({
    name: 'settings_inbox_show',
    params: {
      accountId: route.params.accountId,
      inboxId: inbox.id,
    },
  });
};

const setInboxPolicy = async (inboxId, policyId) => {
  try {
    await store.dispatch('assignmentPolicies/setInboxPolicy', {
      inboxId,
      policyId,
    });
    useAlert(t(`${BASE_KEY}.FORM.INBOXES.API.SUCCESS_MESSAGE`));
    await store.dispatch(
      'assignmentPolicies/getInboxes',
      Number(routeId.value)
    );
    return true;
  } catch (error) {
    useAlert(t(`${BASE_KEY}.FORM.INBOXES.API.ERROR_MESSAGE`));
    return false;
  }
};

const handleAddInbox = async inbox => {
  try {
    const policy = await store.dispatch('assignmentPolicies/getInboxPolicy', {
      inboxId: inbox?.id,
    });

    if (policy?.id !== selectedPolicy.value?.id) {
      inboxLinkedPolicy.value = {
        ...policy,
        assignedInboxCount: policy.assignedInboxCount - 1,
      };
      confirmInboxDialogRef.value.openDialog(inbox);
      return;
    }
  } catch (error) {
    // If getInboxPolicy fails, continue to setInboxPolicy
  }

  await setInboxPolicy(inbox?.id, selectedPolicy.value?.id);
};

const handleLinkSuggestedInbox = async () => {
  if (!suggestedInbox.value) return;

  isLinkingInbox.value = true;
  const inbox = {
    id: suggestedInbox.value.id,
    name: suggestedInbox.value.name,
  };

  await handleAddInbox(inbox);

  // Clear the query param after linking
  router.replace({
    name: route.name,
    params: route.params,
    query: {},
  });
  isLinkingInbox.value = false;
};

const handleConfirmAddInbox = async inboxId => {
  const success = await setInboxPolicy(inboxId, selectedPolicy.value?.id);

  if (success) {
    // Update the policy to reflect the assigned inbox count change
    await store.dispatch('assignmentPolicies/updateInboxPolicy', {
      policy: inboxLinkedPolicy.value,
    });
    // Fetch the updated inboxes for the policy after update, to reflect real-time changes
    store.dispatch(
      'assignmentPolicies/getInboxes',
      inboxLinkedPolicy.value?.id
    );
    inboxLinkedPolicy.value = null;
    confirmInboxDialogRef.value.closeDialog();
  }
};

const handleSubmit = async formState => {
  try {
    await store.dispatch('assignmentPolicies/update', {
      id: selectedPolicy.value?.id,
      ...formState,
    });
    useAlert(t(`${BASE_KEY}.EDIT.API.SUCCESS_MESSAGE`));
  } catch {
    useAlert(t(`${BASE_KEY}.EDIT.API.ERROR_MESSAGE`));
  }
};

const fetchPolicyData = async () => {
  if (!routeId.value) return;

  // Fetch inboxes if not already loaded (needed for inbox link prompt)
  if (!inboxes.value?.length) {
    store.dispatch('inboxes/get');
  }

  // Fetch policy if not available
  if (!selectedPolicy.value?.id)
    await store.dispatch('assignmentPolicies/show', routeId.value);

  await store.dispatch('assignmentPolicies/getInboxes', Number(routeId.value));
};

watch(routeId, fetchPolicyData, { immediate: true });
</script>

<template>
  <SettingsLayout :is-loading="uiFlags.isFetchingItem" class="xl:px-44">
    <template #header>
      <div class="flex items-center gap-2 w-full justify-between">
        <Breadcrumb :items="breadcrumbItems" @click="handleBreadcrumbClick" />
      </div>
    </template>

    <template #body>
      <AssignmentPolicyForm
        :key="routeId"
        mode="EDIT"
        :initial-data="formData"
        :policy-inboxes="policyInboxes"
        :inbox-list="inboxList"
        show-inbox-section
        :is-loading="uiFlags.isUpdating"
        :is-inbox-loading="inboxUiFlags.isFetching"
        @submit="handleSubmit"
        @add-inbox="handleAddInbox"
        @delete-inbox="handleDeleteInbox"
        @navigate-to-inbox="handleNavigateToInbox"
      />
    </template>

    <ConfirmInboxDialog
      ref="confirmInboxDialogRef"
      @add="handleConfirmAddInbox"
    />

    <InboxLinkDialog
      :inbox="suggestedInbox"
      :is-linking="isLinkingInbox"
      @link="handleLinkSuggestedInbox"
      @dismiss="dismissInboxLinkPrompt"
    />
  </SettingsLayout>
</template>
