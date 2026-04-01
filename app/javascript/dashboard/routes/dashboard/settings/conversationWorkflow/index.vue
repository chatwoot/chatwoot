<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import SettingsLayout from '../SettingsLayout.vue';
import CustomBrandPolicyWrapper from 'dashboard/components/CustomBrandPolicyWrapper.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { getHelpUrlForFeature } from 'dashboard/helper/featureHelper';
import ConversationRequiredAttributes from 'dashboard/components-next/ConversationWorkflow/ConversationRequiredAttributes.vue';
import AutoResolve from 'dashboard/routes/dashboard/settings/account/components/AutoResolve.vue';

const { t } = useI18n();
const { accountId } = useAccount();
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const helpURL = computed(() => getHelpUrlForFeature('conversation_workflow'));

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
</script>

<template>
  <SettingsLayout class="gap-8">
    <template #header>
      <div class="flex flex-col gap-6 pb-2">
        <div class="min-w-0 space-y-2">
          <p
            class="mb-0 text-[11px] font-bold uppercase tracking-widest text-on-surface-variant/70"
          >
            {{ t('CONVERSATION_WORKFLOW.INDEX.HEADER.PAGE_EYEBROW') }}
          </p>
          <h2 class="mb-0 text-3xl font-bold tracking-tight text-on-surface">
            {{ t('CONVERSATION_WORKFLOW.INDEX.HEADER.TITLE') }}
          </h2>
          <p class="mb-0 max-w-2xl text-base text-on-primary-container">
            {{ t('CONVERSATION_WORKFLOW.INDEX.HEADER.PAGE_SUBTITLE') }}
          </p>
          <CustomBrandPolicyWrapper :show-on-custom-branded-instance="false">
            <a
              v-if="helpURL"
              :href="helpURL"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex items-center gap-1 text-sm font-medium text-secondary hover:underline"
            >
              {{ t('CONVERSATION_WORKFLOW.INDEX.HEADER.LEARN_MORE') }}
              <Icon icon="i-lucide-chevron-right" class="size-4 shrink-0" />
            </a>
          </CustomBrandPolicyWrapper>
        </div>
      </div>
    </template>

    <template #body>
      <div class="flex flex-col gap-6">
        <AutoResolve v-if="showAutoResolutionConfig" />
        <ConversationRequiredAttributes :is-enabled="showRequiredAttributes" />
      </div>
    </template>
  </SettingsLayout>
</template>
