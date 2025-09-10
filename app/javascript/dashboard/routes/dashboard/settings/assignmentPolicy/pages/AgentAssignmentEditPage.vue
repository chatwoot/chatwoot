<script setup>
import { computed, reactive, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useConfig } from 'dashboard/composables/useConfig';
import { getInboxIconByType } from 'dashboard/helper/inbox';

import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseInfo from 'dashboard/components-next/AssignmentPolicy/components/BaseInfo.vue';
import RadioCard from 'dashboard/components-next/AssignmentPolicy/components/RadioCard.vue';
import FairDistribution from 'dashboard/components-next/AssignmentPolicy/components/FairDistribution.vue';
import DataTable from 'dashboard/components-next/AssignmentPolicy/components/DataTable.vue';
import AddDataDropdown from 'dashboard/components-next/AssignmentPolicy/components/AddDataDropdown.vue';
import ConfirmInboxDialog from 'dashboard/routes/dashboard/settings/assignmentPolicy/pages/components/ConfirmInboxDialog.vue';

const OPTIONS = {
  ORDER: ['round_robin', 'balanced'],
  PRIORITY: ['earliest_created', 'longest_waiting'],
};

const BASE_KEY = 'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY';

const DEFAULT_FAIR_DISTRIBUTION_LIMIT = 100;
const DEFAULT_FAIR_DISTRIBUTION_WINDOW = 3600;

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const store = useStore();
const { isEnterprise } = useConfig();

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

const state = reactive({
  name: '',
  description: '',
  enabled: false,
  assignmentOrder: '',
  conversationPriority: '',
  fairDistributionLimit: DEFAULT_FAIR_DISTRIBUTION_LIMIT,
  fairDistributionWindow: DEFAULT_FAIR_DISTRIBUTION_WINDOW,
});

const validationState = ref({
  isValid: false,
});

const breadcrumbItems = computed(() => [
  {
    label: t(`${BASE_KEY}.INDEX.HEADER.TITLE`),
    routeName: 'agent_assignment_policy_index',
  },
  { label: t(`${BASE_KEY}.EDIT.HEADER.TITLE`) },
]);

const createOption = (type, key, stateKey) => ({
  key,
  label: t(`${BASE_KEY}.FORM.${type}.${key.toUpperCase()}.LABEL`),
  description: t(`${BASE_KEY}.FORM.${type}.${key.toUpperCase()}.DESCRIPTION`),
  isActive: state[stateKey] === key,
});

const assignmentOrderOptions = computed(() => {
  const options = OPTIONS.ORDER.filter(
    key => isEnterprise || key !== 'balanced'
  );
  return options.map(key =>
    createOption('ASSIGNMENT_ORDER', key, 'assignmentOrder')
  );
});

const assignmentPriorityOptions = computed(() =>
  OPTIONS.PRIORITY.map(key =>
    createOption('ASSIGNMENT_PRIORITY', key, 'conversationPriority')
  )
);

const radioSections = computed(() => [
  {
    key: 'assignmentOrder',
    label: t(`${BASE_KEY}.FORM.ASSIGNMENT_ORDER.LABEL`),
    options: assignmentOrderOptions.value,
  },
  {
    key: 'conversationPriority',
    label: t(`${BASE_KEY}.FORM.ASSIGNMENT_PRIORITY.LABEL`),
    options: assignmentPriorityOptions.value,
  },
]);

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

const handleDeleteInbox = inboxId =>
  store.dispatch('assignmentPolicies/removeInboxPolicy', {
    policyId: selectedPolicy.value?.id,
    inboxId,
  });

const handleBreadcrumbClick = ({ routeName }) =>
  router.push({ name: routeName });

const setSelectedPolicy = () => {
  if (!selectedPolicy.value) return;

  Object.assign(state, {
    name: selectedPolicy.value.name || '',
    description: selectedPolicy.value.description || '',
    enabled: selectedPolicy.value.enabled || false,
    assignmentOrder: selectedPolicy.value.assignmentOrder || '',
    conversationPriority: selectedPolicy.value.conversationPriority || '',
    fairDistributionLimit:
      selectedPolicy.value.fairDistributionLimit ||
      DEFAULT_FAIR_DISTRIBUTION_LIMIT,
    fairDistributionWindow:
      selectedPolicy.value.fairDistributionWindow ||
      DEFAULT_FAIR_DISTRIBUTION_WINDOW,
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

const handleValidationChange = validation => {
  validationState.value = validation;
};

const onClickUpdatePolicy = async () => {
  try {
    await store.dispatch('assignmentPolicies/update', {
      id: selectedPolicy.value?.id,
      ...state,
    });
    useAlert(t(`${BASE_KEY}.EDIT.API.SUCCESS_MESSAGE`));
  } catch {
    useAlert(t(`${BASE_KEY}.EDIT.API.ERROR_MESSAGE`));
  }
};

const fetchPolicyData = async () => {
  if (!routeId.value) return;

  // Fetch policy if not available
  if (!selectedPolicy.value?.id)
    await store.dispatch('assignmentPolicies/show', routeId.value);

  setSelectedPolicy();

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
      <div class="flex flex-col gap-4 divide-y divide-n-weak">
        <BaseInfo
          v-model:policy-name="state.name"
          v-model:description="state.description"
          v-model:enabled="state.enabled"
          :name-label="t(`${BASE_KEY}.FORM.NAME.LABEL`)"
          :name-placeholder="t(`${BASE_KEY}.FORM.NAME.PLACEHOLDER`)"
          :description-label="t(`${BASE_KEY}.FORM.DESCRIPTION.LABEL`)"
          :description-placeholder="
            t(`${BASE_KEY}.FORM.DESCRIPTION.PLACEHOLDER`)
          "
          :status-label="t(`${BASE_KEY}.FORM.STATUS.LABEL`)"
          :status-placeholder="
            t(
              `${BASE_KEY}.FORM.STATUS.${state.enabled ? 'ACTIVE' : 'INACTIVE'}`
            )
          "
          @validation-change="handleValidationChange"
        />

        <div class="flex flex-col items-center">
          <div
            v-for="section in radioSections"
            :key="section.key"
            class="py-4 flex flex-col items-start gap-3 w-full"
          >
            <label class="text-sm font-medium text-n-slate-12 py-1">
              {{ section.label }}
            </label>
            <div class="grid grid-cols-1 xs:grid-cols-2 gap-4 w-full">
              <RadioCard
                v-for="option in section.options"
                :id="option.key"
                :key="option.key"
                :label="option.label"
                :description="option.description"
                :is-active="option.isActive"
                @select="state[section.key] = $event"
              />
            </div>
          </div>
        </div>

        <div class="pt-4 pb-2 flex-col flex gap-4">
          <div class="flex flex-col items-start gap-1 py-1">
            <label class="text-sm font-medium text-n-slate-12 py-1">
              {{ t(`${BASE_KEY}.FORM.FAIR_DISTRIBUTION.LABEL`) }}
            </label>
            <p class="mb-0 text-n-slate-11 text-sm">
              {{ t(`${BASE_KEY}.FORM.FAIR_DISTRIBUTION.DESCRIPTION`) }}
            </p>
          </div>
          <FairDistribution
            :key="routeId"
            v-model:fair-distribution-limit="state.fairDistributionLimit"
            v-model:fair-distribution-window="state.fairDistributionWindow"
            v-model:window-unit="state.windowUnit"
          />
        </div>

        <div class="py-4 flex-col flex gap-4">
          <div class="flex items-end gap-4 w-full justify-between">
            <div class="flex flex-col items-start gap-1 py-1">
              <label class="text-sm font-medium text-n-slate-12 py-1">
                {{ t(`${BASE_KEY}.FORM.INBOXES.LABEL`) }}
              </label>
              <p class="mb-0 text-n-slate-11 text-sm">
                {{ t(`${BASE_KEY}.FORM.INBOXES.DESCRIPTION`) }}
              </p>
            </div>
            <AddDataDropdown
              :label="t(`${BASE_KEY}.FORM.INBOXES.ADD_BUTTON`)"
              :search-placeholder="
                t(`${BASE_KEY}.FORM.INBOXES.DROPDOWN.SEARCH_PLACEHOLDER`)
              "
              :items="inboxList"
              @add="handleAddInbox"
            />
          </div>
          <DataTable
            :items="policyInboxes"
            :is-fetching="inboxUiFlags.isFetching"
            :empty-state-message="t(`${BASE_KEY}.FORM.INBOXES.EMPTY_STATE`)"
            @delete="handleDeleteInbox"
          />
        </div>
      </div>

      <Button
        type="button"
        :label="t(`${BASE_KEY}.EDIT.UPDATE_BUTTON`)"
        :disabled="!validationState.isValid || uiFlags.isUpdating"
        :is-loading="uiFlags.isUpdating"
        @click="onClickUpdatePolicy"
      />
    </template>

    <ConfirmInboxDialog
      ref="confirmInboxDialogRef"
      @add="handleConfirmAddInbox"
    />
  </SettingsLayout>
</template>
