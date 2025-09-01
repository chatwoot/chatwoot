<script setup>
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import SamlSettings from './components/SamlSettings.vue';
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
        feature-name="security"
      />
    </template>
    <template #body>
      <SamlSettings />
    </template>
  </SettingsLayout>
</template>
