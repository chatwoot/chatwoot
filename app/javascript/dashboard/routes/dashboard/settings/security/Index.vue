<script setup>
import { computed } from 'vue';
import { parseBoolean } from '@chatwoot/utils';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SamlSettings from './components/SamlSettings.vue';
import SamlPaywall from './components/SamlPaywall.vue';
import EnforceMfa from './components/EnforceMfa.vue';

import { usePolicy } from 'dashboard/composables/usePolicy';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
const { shouldShow, shouldShowPaywall } = usePolicy();

const allowedLoginMethods = computed(
  () => window.chatwootConfig.allowedLoginMethods || ['email']
);

const isSamlSsoEnabled = computed(() =>
  allowedLoginMethods.value.includes('saml')
);

const shouldShowSaml = computed(() => {
  const hasPermission = shouldShow(
    FEATURE_FLAGS.SAML,
    ['administrator'],
    [INSTALLATION_TYPES.CLOUD, INSTALLATION_TYPES.ENTERPRISE]
  );
  return hasPermission && isSamlSsoEnabled.value;
});

const showPaywall = computed(() => shouldShowPaywall('saml'));

const isMfaAvailable = computed(() =>
  parseBoolean(window.chatwootConfig?.isMfaEnabled)
);

// SAML is cloud/enterprise; self-hosted community reaches this page for MFA only.
const showSamlSection = computed(
  () =>
    showPaywall.value ||
    shouldShow(
      FEATURE_FLAGS.SAML,
      ['administrator'],
      [INSTALLATION_TYPES.CLOUD, INSTALLATION_TYPES.ENTERPRISE]
    )
);
</script>

<template>
  <SettingsLayout :loading-message="$t('ATTRIBUTES_MGMT.LOADING')">
    <template #header>
      <BaseSettingsHeader
        :title="$t('SECURITY_SETTINGS.TITLE')"
        :description="$t('SECURITY_SETTINGS.DESCRIPTION')"
        :link-text="$t('SECURITY_SETTINGS.LINK_TEXT')"
        feature-name="saml"
      />
    </template>
    <template #body>
      <EnforceMfa v-if="isMfaAvailable" />
      <template v-if="showSamlSection">
        <SamlPaywall v-if="showPaywall" />
        <SamlSettings v-else-if="shouldShowSaml" />
        <div v-else class="mt-6 text-sm text-slate-600">
          {{ $t('SECURITY_SETTINGS.SAML_DISABLED_MESSAGE') }}
        </div>
      </template>
    </template>
  </SettingsLayout>
</template>
