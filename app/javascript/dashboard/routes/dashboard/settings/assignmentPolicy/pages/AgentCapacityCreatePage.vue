<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';

import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import AgentCapacityPolicyForm from 'dashboard/routes/dashboard/settings/assignmentPolicy/pages/components/AgentCapacityPolicyForm.vue';

const router = useRouter();
const store = useStore();
const { t } = useI18n();

const formRef = ref(null);
const uiFlags = useMapGetter('agentCapacityPolicies/getUIFlags');
const labelsList = useMapGetter('labels/getLabels');

const allLabels = computed(() =>
  labelsList.value?.map(({ title, color, id }) => ({
    id,
    name: title,
    color,
  }))
);

const breadcrumbItems = computed(() => [
  {
    label: t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.INDEX.HEADER.TITLE'),
    routeName: 'agent_capacity_policy_index',
  },
  {
    label: t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.CREATE.HEADER.TITLE'),
  },
]);

const handleBreadcrumbClick = item => {
  router.push({
    name: item.routeName,
  });
};

const handleSubmit = async formState => {
  try {
    const policy = await store.dispatch(
      'agentCapacityPolicies/create',
      formState
    );
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.CREATE.API.SUCCESS_MESSAGE')
    );
    formRef.value?.resetForm();

    router.push({
      name: 'agent_capacity_policy_edit',
      params: {
        id: policy.id,
      },
    });
  } catch (error) {
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.CREATE.API.ERROR_MESSAGE')
    );
  }
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
      <AgentCapacityPolicyForm
        ref="formRef"
        mode="CREATE"
        :is-loading="uiFlags.isCreating"
        :label-list="allLabels"
        @submit="handleSubmit"
      />
    </template>
  </SettingsLayout>
</template>
