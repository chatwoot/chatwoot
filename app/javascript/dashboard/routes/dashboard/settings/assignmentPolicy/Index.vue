<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import AssignmentCard from 'dashboard/components-next/AssignmentPolicy/AssignmentCard/AssignmentCard.vue';

const router = useRouter();
const route = useRoute();
const { t } = useI18n();

const accountId = computed(() => Number(route.params.accountId));
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const agentAssignments = computed(() => {
  const assignments = [
    {
      key: 'agent_assignment_policy_index',
      title: t('ASSIGNMENT_POLICY.INDEX.ASSIGNMENT_POLICY.TITLE'),
      description: t('ASSIGNMENT_POLICY.INDEX.ASSIGNMENT_POLICY.DESCRIPTION'),
      features: [
        {
          icon: 'i-lucide-circle-fading-arrow-up',
          label: t('ASSIGNMENT_POLICY.INDEX.ASSIGNMENT_POLICY.FEATURES.0'),
        },
        {
          icon: 'i-lucide-scale',
          label: t('ASSIGNMENT_POLICY.INDEX.ASSIGNMENT_POLICY.FEATURES.1'),
        },
        {
          icon: 'i-lucide-inbox',
          label: t('ASSIGNMENT_POLICY.INDEX.ASSIGNMENT_POLICY.FEATURES.2'),
        },
      ],
    },
  ];

  // Only show Agent Capacity if BOTH assignment_v2 AND advanced_assignment are enabled
  // advanced_assignment identifies premium users
  const hasAssignmentV2 = isFeatureEnabledonAccount.value(
    accountId.value,
    'assignment_v2'
  );
  const hasAdvancedAssignment = isFeatureEnabledonAccount.value(
    accountId.value,
    'advanced_assignment'
  );

  if (hasAssignmentV2 && hasAdvancedAssignment) {
    assignments.push({
      key: 'agent_capacity_policy_index',
      title: t('ASSIGNMENT_POLICY.INDEX.AGENT_CAPACITY_POLICY.TITLE'),
      description: t(
        'ASSIGNMENT_POLICY.INDEX.AGENT_CAPACITY_POLICY.DESCRIPTION'
      ),
      features: [
        {
          icon: 'i-lucide-glass-water',
          label: t('ASSIGNMENT_POLICY.INDEX.AGENT_CAPACITY_POLICY.FEATURES.0'),
        },
        {
          icon: 'i-lucide-circle-minus',
          label: t('ASSIGNMENT_POLICY.INDEX.AGENT_CAPACITY_POLICY.FEATURES.1'),
        },
        {
          icon: 'i-lucide-users-round',
          label: t('ASSIGNMENT_POLICY.INDEX.AGENT_CAPACITY_POLICY.FEATURES.2'),
        },
      ],
    });
  }

  return assignments;
});

const handleClick = key => {
  router.push({ name: key });
};
</script>

<template>
  <SettingsLayout :no-records-found="false" class="gap-10">
    <template #header>
      <BaseSettingsHeader
        :title="$t('ASSIGNMENT_POLICY.INDEX.HEADER.TITLE')"
        :description="$t('ASSIGNMENT_POLICY.INDEX.HEADER.DESCRIPTION')"
        feature-name="assignment-policy"
      />
    </template>

    <template #body>
      <div class="grid grid-cols-1 2xl:grid-cols-2 gap-6 mt-4">
        <AssignmentCard
          v-for="item in agentAssignments"
          :key="item.key"
          :title="item.title"
          :description="item.description"
          :features="item.features"
          @click="handleClick(item.key)"
        />
      </div>
    </template>
  </SettingsLayout>
</template>
