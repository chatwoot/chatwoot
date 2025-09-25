<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';

import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import AssignmentPolicyForm from 'dashboard/routes/dashboard/settings/assignmentPolicy/pages/components/AgentAssignmentPolicyForm.vue';

const router = useRouter();
const store = useStore();
const { t } = useI18n();

const formRef = ref(null);
const uiFlags = useMapGetter('assignmentPolicies/getUIFlags');

const breadcrumbItems = computed(() => [
  {
    label: t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.INDEX.HEADER.TITLE'),
    routeName: 'agent_assignment_policy_index',
  },
  {
    label: t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.CREATE.HEADER.TITLE'),
  },
]);

const handleBreadcrumbClick = item => {
  router.push({
    name: item.routeName,
  });
};

const handleSubmit = async formState => {
  try {
    const policy = await store.dispatch('assignmentPolicies/create', formState);
    useAlert(
      t('ASSIGNMENT_POLICY.AGENT_ASSIGNMENT_POLICY.CREATE.API.SUCCESS_MESSAGE')
    );
    formRef.value?.resetForm();

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
</script>

<template>
  <SettingsLayout class="xl:px-44">
    <template #header>
      <div class="flex items-center gap-2 w-full justify-between">
        <Breadcrumb :items="breadcrumbItems" @click="handleBreadcrumbClick" />
      </div>
    </template>

    <template #body>
      <AssignmentPolicyForm
        ref="formRef"
        mode="CREATE"
        :is-loading="uiFlags.isCreating"
        @submit="handleSubmit"
      />
    </template>
  </SettingsLayout>
</template>
