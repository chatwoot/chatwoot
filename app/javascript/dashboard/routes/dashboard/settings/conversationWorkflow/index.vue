<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ConversationRequiredAttributes from 'dashboard/components-next/ConversationWorkflow/ConversationRequiredAttributes.vue';
import AutoResolve from 'dashboard/routes/dashboard/settings/account/components/AutoResolve.vue';

const { accountId } = useAccount();
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);
const { isEnterprise } = useConfig();

const showAutoResolutionConfig = computed(() => {
  return isFeatureEnabledonAccount.value(
    accountId.value,
    FEATURE_FLAGS.AUTO_RESOLVE_CONVERSATIONS
  );
});
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
      <div class="flex flex-col gap-6">
        <AutoResolve v-if="showAutoResolutionConfig" />
        <ConversationRequiredAttributes v-if="isEnterprise" />
      </div>
    </template>
  </SettingsLayout>
</template>
