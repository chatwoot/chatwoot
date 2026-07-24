<script setup>
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ConversationRequiredAttributes from 'dashboard/components-next/ConversationWorkflow/ConversationRequiredAttributes.vue';
import BusinessRulesPanel from 'dashboard/components-next/ConversationWorkflow/BusinessRulesPanel.vue';
import AutoResolve from 'dashboard/routes/dashboard/settings/account/components/AutoResolve.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const router = useRouter();
const { accountId } = useAccount();
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

onMounted(() => {
  store.dispatch('attributes/get');
});

const showAutoResolutionConfig = computed(() => {
  return isFeatureEnabledonAccount.value(
    accountId.value,
    FEATURE_FLAGS.AUTO_RESOLVE_CONVERSATIONS
  );
});

const showRequiredAttributes = computed(() => {
  return isFeatureEnabledonAccount.value(
    accountId.value,
    FEATURE_FLAGS.CONVERSATION_REQUIRED_ATTRIBUTES
  );
});

const showFlows = computed(() => {
  return isFeatureEnabledonAccount.value(
    accountId.value,
    FEATURE_FLAGS.FLOWS_V1
  );
});

const openFlows = () => {
  router.push({ name: 'flows_index' });
};
</script>

<template>
  <SettingsLayout :no-records-found="false" class="gap-10">
    <template #header>
      <BaseSettingsHeader
        :title="$t('CONVERSATION_WORKFLOW.INDEX.HEADER.TITLE')"
        :description="$t('CONVERSATION_WORKFLOW.INDEX.HEADER.DESCRIPTION')"
        feature-name="conversation-workflow"
      />
    </template>

    <template #body>
      <div class="flex flex-col gap-6 mt-4">
        <div
          v-if="showFlows"
          class="flex flex-col gap-3 rounded-lg border border-n-weak bg-n-solid-2 p-4 sm:flex-row sm:items-center sm:justify-between"
        >
          <div class="flex flex-col gap-1">
            <p class="font-medium text-n-slate-12">
              {{ $t('CONVERSATION_WORKFLOW.FLOWS.TITLE') }}
            </p>
            <p class="text-sm text-n-slate-11">
              {{ $t('CONVERSATION_WORKFLOW.FLOWS.DESCRIPTION') }}
            </p>
          </div>
          <Button
            :label="$t('CONVERSATION_WORKFLOW.FLOWS.CTA')"
            @click="openFlows"
          />
        </div>
        <AutoResolve v-if="showAutoResolutionConfig" />
        <ConversationRequiredAttributes :is-enabled="showRequiredAttributes" />
        <BusinessRulesPanel />
      </div>
    </template>
  </SettingsLayout>
</template>
