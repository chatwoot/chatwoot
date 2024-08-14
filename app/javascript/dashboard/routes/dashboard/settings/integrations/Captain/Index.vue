<script setup>
import IntegrationSettingsLayout from '../Layout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
</script>

<template>
  <IntegrationSettingsLayout>
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.CAPTAIN.TITLE')"
        :description="$t('INTEGRATION_SETTINGS.CAPTAIN.DESCRIPTION')"
        :link-text="$t('INTEGRATION_SETTINGS.CAPTAIN.LEARN_MORE')"
        feature-name="captain"
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
      >
        <template #actions>
          <woot-button class="rounded-md button nice" icon="add-circle">
            {{ $t('INTEGRATION_SETTINGS.CAPTAIN.HEADER_BTN_TXT') }}
          </woot-button>
        </template>
      </BaseSettingsHeader>
    </template>
  </IntegrationSettingsLayout>
</template>
