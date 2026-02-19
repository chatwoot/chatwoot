<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import BaseInfo from 'dashboard/components-next/AssignmentPolicy/components/BaseInfo.vue';
import RadioCard from 'dashboard/components-next/AssignmentPolicy/components/RadioCard.vue';
import FairDistribution from 'dashboard/components-next/AssignmentPolicy/components/FairDistribution.vue';
import DataTable from 'dashboard/components-next/AssignmentPolicy/components/DataTable.vue';
import AddDataDropdown from 'dashboard/components-next/AssignmentPolicy/components/AddDataDropdown.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import {
  OPTIONS,
  ROUND_ROBIN,
  EARLIEST_CREATED,
  DEFAULT_FAIR_DISTRIBUTION_LIMIT,
  DEFAULT_FAIR_DISTRIBUTION_WINDOW,
} from 'dashboard/routes/dashboard/settings/assignmentPolicy/constants';

const props = defineProps({
  initialData: {
    type: Object,
    default: () => ({
      name: '',
      description: '',
      assignmentOrder: ROUND_ROBIN,
      conversationPriority: EARLIEST_CREATED,
      fairDistributionLimit: DEFAULT_FAIR_DISTRIBUTION_LIMIT,
      fairDistributionWindow: DEFAULT_FAIR_DISTRIBUTION_WINDOW,
    }),
  },
  mode: {
    type: String,
    required: true,
    validator: value => ['CREATE', 'EDIT'].includes(value),
  },
  policyInboxes: {
    type: Array,
    default: () => [],
  },
  inboxList: {
    type: Array,
    default: () => [],
  },
  showInboxSection: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isInboxLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'submit',
  'addInbox',
  'deleteInbox',
  'navigateToInbox',
  'validationChange',
]);

const { t } = useI18n();
const route = useRoute();

const accountId = computed(() => Number(route.params.accountId));
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const BASE_KEY = 'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY';

const state = reactive({
  name: '',
  description: '',
  enabled: true,
  assignmentOrder: ROUND_ROBIN,
  conversationPriority: EARLIEST_CREATED,
  fairDistributionLimit: DEFAULT_FAIR_DISTRIBUTION_LIMIT,
  fairDistributionWindow: DEFAULT_FAIR_DISTRIBUTION_WINDOW,
});

const validationState = ref({
  isValid: false,
});

const createOption = (
  type,
  key,
  stateKey,
  disabled = false,
  disabledMessage = '',
  disabledLabel = ''
) => ({
  key,
  label: t(`${BASE_KEY}.FORM.${type}.${key.toUpperCase()}.LABEL`),
  description: t(`${BASE_KEY}.FORM.${type}.${key.toUpperCase()}.DESCRIPTION`),
  isActive: state[stateKey] === key,
  disabled,
  disabledMessage,
  disabledLabel,
});

const assignmentOrderOptions = computed(() => {
  const hasAdvancedAssignment = isFeatureEnabledonAccount.value(
    accountId.value,
    'advanced_assignment'
  );

  return OPTIONS.ORDER.map(key => {
    const isBalanced = key === 'balanced';
    const disabled = isBalanced && !hasAdvancedAssignment;
    const disabledMessage = disabled
      ? t(`${BASE_KEY}.FORM.ASSIGNMENT_ORDER.BALANCED.PREMIUM_MESSAGE`)
      : '';
    const disabledLabel = disabled
      ? t(`${BASE_KEY}.FORM.ASSIGNMENT_ORDER.BALANCED.PREMIUM_BADGE`)
      : '';

    return createOption(
      'ASSIGNMENT_ORDER',
      key,
      'assignmentOrder',
      disabled,
      disabledMessage,
      disabledLabel
    );
  });
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

const buttonLabel = computed(() =>
  t(`${BASE_KEY}.${props.mode.toUpperCase()}.${props.mode}_BUTTON`)
);

const handleValidationChange = validation => {
  validationState.value = validation;
  emit('validationChange', validation);
};

const resetForm = () => {
  Object.assign(state, {
    name: '',
    description: '',
    enabled: true,
    assignmentOrder: ROUND_ROBIN,
    conversationPriority: EARLIEST_CREATED,
    fairDistributionLimit: DEFAULT_FAIR_DISTRIBUTION_LIMIT,
    fairDistributionWindow: DEFAULT_FAIR_DISTRIBUTION_WINDOW,
  });
};

const handleSubmit = () => {
  emit('submit', { ...state });
};

watch(
  () => props.initialData,
  newData => {
    Object.assign(state, newData);
  },
  { immediate: true, deep: true }
);

defineExpose({
  resetForm,
});
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <div class="flex flex-col gap-4 divide-y divide-n-weak mb-4">
      <BaseInfo
        v-model:policy-name="state.name"
        v-model:description="state.description"
        :name-label="t(`${BASE_KEY}.FORM.NAME.LABEL`)"
        :name-placeholder="t(`${BASE_KEY}.FORM.NAME.PLACEHOLDER`)"
        :description-label="t(`${BASE_KEY}.FORM.DESCRIPTION.LABEL`)"
        :description-placeholder="t(`${BASE_KEY}.FORM.DESCRIPTION.PLACEHOLDER`)"
        @validation-change="handleValidationChange"
      />

      <div class="flex flex-col items-center">
        <div
          v-for="section in radioSections"
          :key="section.key"
          class="py-4 flex flex-col items-start gap-3 w-full"
        >
          <WithLabel
            :label="section.label"
            name="assignmentPolicy"
            class="w-full flex items-start flex-col gap-3"
          >
            <div class="grid grid-cols-1 xs:grid-cols-2 gap-4 w-full">
              <RadioCard
                v-for="option in section.options"
                :id="option.key"
                :key="option.key"
                :label="option.label"
                :description="option.description"
                :is-active="option.isActive"
                :disabled="option.disabled"
                :disabled-label="option.disabledLabel"
                :disabled-message="option.disabledMessage"
                @select="state[section.key] = $event"
              />
            </div>
          </WithLabel>
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
          v-model:fair-distribution-limit="state.fairDistributionLimit"
          v-model:fair-distribution-window="state.fairDistributionWindow"
          v-model:window-unit="state.windowUnit"
        />
      </div>
    </div>

    <Button
      type="submit"
      :label="buttonLabel"
      :disabled="!validationState.isValid || isLoading"
      :is-loading="isLoading"
    />

    <div
      v-if="showInboxSection"
      class="py-4 flex-col flex gap-4 border-t border-n-weak mt-6"
    >
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
          @add="$emit('addInbox', $event)"
        />
      </div>
      <DataTable
        :items="policyInboxes"
        :is-fetching="isInboxLoading"
        :empty-state-message="t(`${BASE_KEY}.FORM.INBOXES.EMPTY_STATE`)"
        @delete="$emit('deleteInbox', $event)"
        @navigate="$emit('navigateToInbox', $event)"
      />
    </div>
  </form>
</template>
