<script setup>
import { computed } from 'vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SamlSettings from './components/SamlSettings.vue';
import SamlPaywall from './components/SamlPaywall.vue';

import { usePolicy } from 'dashboard/composables/usePolicy';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
const { shouldShow, shouldShowPaywall } = usePolicy();

const shouldShowSaml = computed(() =>
  shouldShow(
    FEATURE_FLAGS.SAML,
    ['administrator'],
    [INSTALLATION_TYPES.CLOUD, INSTALLATION_TYPES.ENTERPRISE]
  )
);
const showPaywall = computed(() => shouldShowPaywall('saml'));
</script>

<template>
  <SettingsLayout
    class="max-w-2xl mx-auto"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('SECURITY_SETTINGS.TITLE')"
        :description="$t('SECURITY_SETTINGS.DESCRIPTION')"
        :link-text="$t('SECURITY_SETTINGS.LINK_TEXT')"
        feature-name="saml"
      />
    </template>
    <template #body>
      <SamlPaywall v-if="showPaywall" />
      <SamlSettings v-else-if="shouldShowSaml" />
    </template>
  </SettingsLayout>
</template>
