<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import BaseInfo from 'dashboard/components-next/AssignmentPolicy/components/BaseInfo.vue';
import DataTable from 'dashboard/components-next/AssignmentPolicy/components/DataTable.vue';
import AddDataDropdown from 'dashboard/components-next/AssignmentPolicy/components/AddDataDropdown.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ExclusionRules from 'dashboard/components-next/AssignmentPolicy/components/ExclusionRules.vue';
import InboxCapacityLimits from 'dashboard/components-next/AssignmentPolicy/components/InboxCapacityLimits.vue';

const props = defineProps({
  initialData: {
    type: Object,
    default: () => ({
      name: '',
      description: '',
      enabled: false,
      exclusionRules: {
        excludedLabels: [],
        excludeOlderThanHours: 10,
      },
      inboxCapacityLimits: [],
    }),
  },
  mode: {
    type: String,
    required: true,
    validator: value => ['CREATE', 'EDIT'].includes(value),
  },
  policyUsers: {
    type: Array,
    default: () => [],
  },
  agentList: {
    type: Array,
    default: () => [],
  },
  labelList: {
    type: Array,
    default: () => [],
  },
  inboxList: {
    type: Array,
    default: () => [],
  },
  showUserSection: {
    type: Boolean,
    default: false,
  },
  showInboxLimitSection: {
    type: Boolean,
    default: false,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isUsersLoading: {
    type: Boolean,
    default: false,
  },
  isInboxesLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'submit',
  'addUser',
  'deleteUser',
  'validationChange',
  'deleteInboxLimit',
  'addInboxLimit',
  'updateInboxLimit',
]);

const { t } = useI18n();

const BASE_KEY = 'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY';

const state = reactive({
  name: '',
  description: '',
  exclusionRules: {
    excludedLabels: [],
    excludeOlderThanHours: 10,
  },
  inboxCapacityLimits: [],
});

const validationState = ref({
  isValid: false,
});

const buttonLabel = computed(() =>
  t(`${BASE_KEY}.${props.mode.toUpperCase()}.${props.mode}_BUTTON`)
);

const handleValidationChange = validation => {
  validationState.value = validation;
  emit('validationChange', validation);
};

const handleDeleteInboxLimit = id => {
  emit('deleteInboxLimit', id);
};

const handleAddInboxLimit = limit => {
  emit('addInboxLimit', limit);
};

const handleLimitChange = limit => {
  emit('updateInboxLimit', limit);
};

const resetForm = () => {
  Object.assign(state, {
    name: '',
    description: '',
    exclusionRules: {
      excludedLabels: [],
      excludeOlderThanHours: 10,
    },
    inboxCapacityLimits: [],
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
    <div class="flex flex-col gap-4 mb-2 divide-y divide-n-weak">
      <BaseInfo
        v-model:policy-name="state.name"
        v-model:description="state.description"
        :name-label="t(`${BASE_KEY}.FORM.NAME.LABEL`)"
        :name-placeholder="t(`${BASE_KEY}.FORM.NAME.PLACEHOLDER`)"
        :description-label="t(`${BASE_KEY}.FORM.DESCRIPTION.LABEL`)"
        :description-placeholder="t(`${BASE_KEY}.FORM.DESCRIPTION.PLACEHOLDER`)"
        @validation-change="handleValidationChange"
      />
      <ExclusionRules
        v-model:excluded-labels="state.exclusionRules.excludedLabels"
        v-model:exclude-older-than-minutes="
          state.exclusionRules.excludeOlderThanHours
        "
        :tags-list="labelList"
      />
    </div>
    <Button
      type="submit"
      :label="buttonLabel"
      :disabled="!validationState.isValid || isLoading"
      :is-loading="isLoading"
    />

    <div
      v-if="showInboxLimitSection || showUserSection"
      class="flex flex-col gap-4 divide-y divide-n-weak border-t border-n-weak mt-6"
    >
      <InboxCapacityLimits
        v-if="showInboxLimitSection"
        v-model:inbox-capacity-limits="state.inboxCapacityLimits"
        :inbox-list="inboxList"
        :is-fetching="isInboxesLoading"
        @delete="handleDeleteInboxLimit"
        @add="handleAddInboxLimit"
        @update="handleLimitChange"
      />
      <div v-if="showUserSection" class="py-4 flex-col flex gap-4">
        <div class="flex items-end gap-4 w-full justify-between">
          <div class="flex flex-col items-start gap-1 py-1">
            <label class="text-sm font-medium text-n-slate-12 py-1">
              {{ t(`${BASE_KEY}.FORM.USERS.LABEL`) }}
            </label>
            <p class="mb-0 text-n-slate-11 text-sm">
              {{ t(`${BASE_KEY}.FORM.USERS.DESCRIPTION`) }}
            </p>
          </div>
          <AddDataDropdown
            :label="t(`${BASE_KEY}.FORM.USERS.ADD_BUTTON`)"
            :search-placeholder="
              t(`${BASE_KEY}.FORM.USERS.DROPDOWN.SEARCH_PLACEHOLDER`)
            "
            :items="agentList"
            @add="$emit('addUser', $event)"
          />
        </div>
        <DataTable
          :items="policyUsers"
          :is-fetching="isUsersLoading"
          :empty-state-message="t(`${BASE_KEY}.FORM.USERS.EMPTY_STATE`)"
          @delete="$emit('deleteUser', $event)"
        />
      </div>
    </div>
  </form>
</template>
