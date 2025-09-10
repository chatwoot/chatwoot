<script setup>
import { computed, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useConfig } from 'dashboard/composables/useConfig';

import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseInfo from 'dashboard/components-next/AssignmentPolicy/components/BaseInfo.vue';
import RadioCard from 'dashboard/components-next/AssignmentPolicy/components/RadioCard.vue';
import FairDistribution from 'dashboard/components-next/AssignmentPolicy/components/FairDistribution.vue';

const ROUND_ROBIN = 'round_robin';
const BALANCED = 'balanced';
const EARLIEST_CREATED = 'earliest_created';
const LONGEST_WAITING = 'longest_waiting';

const DEFAULT_FAIR_DISTRIBUTION_LIMIT = 100;
const DEFAULT_FAIR_DISTRIBUTION_WINDOW = 3600;

const router = useRouter();
const store = useStore();
const { t } = useI18n();
const { isEnterprise } = useConfig();

const uiFlags = useMapGetter('assignmentPolicies/getUIFlags');

const state = reactive({
  name: '',
  description: '',
  enabled: false,
  assignmentOrder: 'round_robin',
  conversationPriority: 'earliest_created',
  fairDistributionLimit: DEFAULT_FAIR_DISTRIBUTION_LIMIT,
  fairDistributionWindow: DEFAULT_FAIR_DISTRIBUTION_WINDOW,
});

const validationState = ref({
  isValid: false,
});

const breadcrumbItems = computed(() => {
  const items = [
    {
      label: t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.INDEX.HEADER.TITLE'),
      routeName: 'agent_assignment_policy_index',
    },
    {
      label: t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.CREATE.HEADER.TITLE'),
    },
  ];
  return items;
});

const assignmentOrderOptions = computed(() => [
  {
    key: ROUND_ROBIN,
    label: t(
      'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.ASSIGNMENT_ORDER.ROUND_ROBIN.LABEL'
    ),
    description: t(
      'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.ASSIGNMENT_ORDER.ROUND_ROBIN.DESCRIPTION'
    ),
    isActive: state.assignmentOrder === ROUND_ROBIN,
  },
  ...(isEnterprise
    ? [
        {
          key: BALANCED,
          label: t(
            'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.ASSIGNMENT_ORDER.BALANCED.LABEL'
          ),
          description: t(
            'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.ASSIGNMENT_ORDER.BALANCED.DESCRIPTION'
          ),
          isActive: state.assignmentOrder === BALANCED,
        },
      ]
    : []),
]);

const assignmentPriorityOptions = computed(() => {
  return [
    {
      key: EARLIEST_CREATED,
      label: t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.ASSIGNMENT_PRIORITY.EARLIEST_CREATED.LABEL'
      ),
      description: t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.ASSIGNMENT_PRIORITY.EARLIEST_CREATED.DESCRIPTION'
      ),
      isActive: state.conversationPriority === EARLIEST_CREATED,
    },
    {
      key: LONGEST_WAITING,
      label: t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.ASSIGNMENT_PRIORITY.LONGEST_WAITING.LABEL'
      ),
      description: t(
        'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.ASSIGNMENT_PRIORITY.LONGEST_WAITING.DESCRIPTION'
      ),
      isActive: state.conversationPriority === LONGEST_WAITING,
    },
  ];
});

const handleAssignmentOrderChange = value => {
  state.assignmentOrder = value;
};

const handleConversationPriorityChange = value => {
  state.conversationPriority = value;
};

const handleValidationChange = validation => {
  validationState.value = validation;
};

const onClickCreatePolicy = async () => {
  try {
    const policy = await store.dispatch('assignmentPolicies/create', state);
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.CREATE.API.SUCCESS_MESSAGE')
    );
    router.push({
      name: 'agent_assignment_policy_edit',
      params: {
        id: policy.id,
      },
    });
  } catch (error) {
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.CREATE.API.ERROR_MESSAGE')
    );
  }
};

const handleBreadcrumbClick = item => {
  router.push({
    name: item.routeName,
  });
};
</script>

<template>
  <SettingsLayout class="xl:px-44">
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
          :name-label="
            t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.NAME.LABEL')
          "
          :name-placeholder="
            t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.NAME.PLACEHOLDER')
          "
          :description-label="
            t(
              'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.DESCRIPTION.LABEL'
            )
          "
          :description-placeholder="
            t(
              'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.DESCRIPTION.PLACEHOLDER'
            )
          "
          :status-label="
            t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.STATUS.LABEL')
          "
          :status-placeholder="
            state.enabled
              ? t(
                  'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.STATUS.ACTIVE'
                )
              : t(
                  'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.STATUS.INACTIVE'
                )
          "
          @validation-change="handleValidationChange"
        />
        <div class="flex flex-col items-center">
          <div class="py-4 flex flex-col items-start gap-3 w-full">
            <label class="text-sm font-medium text-n-slate-12 py-1">
              {{
                t(
                  'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.ASSIGNMENT_ORDER.LABEL'
                )
              }}
            </label>
            <div class="grid grid-cols-1 xs:grid-cols-2 gap-4 w-full">
              <RadioCard
                v-for="option in assignmentOrderOptions"
                :id="option.key"
                :key="option.key"
                :label="option.label"
                :description="option.description"
                :is-active="option.isActive"
                @select="handleAssignmentOrderChange"
              />
            </div>
          </div>
          <div class="py-4 flex flex-col items-start gap-3 w-full">
            <label class="text-sm font-medium text-n-slate-12 py-1">
              {{
                t(
                  'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.ASSIGNMENT_PRIORITY.LABEL'
                )
              }}
            </label>
            <div class="grid grid-cols-1 xs:grid-cols-2 gap-4 w-full">
              <RadioCard
                v-for="option in assignmentPriorityOptions"
                :id="option.key"
                :key="option.key"
                :label="option.label"
                :description="option.description"
                :is-active="option.isActive"
                @select="handleConversationPriorityChange"
              />
            </div>
          </div>
        </div>
        <div class="py-4 pb-6 flex-col flex gap-4">
          <div class="flex flex-col items-start gap-1 py-1">
            <label class="text-sm font-medium text-n-slate-12 py-1">
              {{
                t(
                  'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.FAIR_DISTRIBUTION.LABEL'
                )
              }}
            </label>
            <p class="mb-0 text-n-slate-11 text-sm">
              {{
                t(
                  'ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.FORM.FAIR_DISTRIBUTION.DESCRIPTION'
                )
              }}
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
        type="button"
        :is-loading="uiFlags.isCreating"
        :disabled="!validationState.isValid || uiFlags.isCreating"
        :label="
          t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.CREATE.CREATE_BUTTON')
        "
        @click="onClickCreatePolicy"
      />
    </template>
  </SettingsLayout>
</template>
