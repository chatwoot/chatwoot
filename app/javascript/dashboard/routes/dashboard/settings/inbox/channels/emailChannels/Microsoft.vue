<script setup>
import { ref } from 'vue';

import { useAlert } from 'dashboard/composables';
import { useI18n } from 'dashboard/composables/useI18n';

import microsoftClient from 'dashboard/api/channel/microsoftClient';
import SettingsSubPageHeader from '../../../SettingsSubPageHeader.vue';

const { t } = useI18n();

const isRequestingAuthorization = ref(false);
const email = ref('');

async function requestAuthorization() {
  try {
    isRequestingAuthorization.value = true;
    const response = await microsoftClient.generateAuthorization({
      email: email.value,
    });
    const {
      data: { url },
    } = response;
    window.location.href = url;
  } catch (error) {
    useAlert(t('INBOX_MGMT.ADD.MICROSOFT.ERROR_MESSAGE'));
  } finally {
    isRequestingAuthorization.value = false;
  }
}
</script>
<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <settings-sub-page-header
      :header-title="$t('INBOX_MGMT.ADD.MICROSOFT.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.MICROSOFT.DESCRIPTION')"
    />
    <form
      class="microsoft--sign-in-form"
      @submit.prevent="requestAuthorization"
    >
      <woot-input
        v-model="email"
        type="email"
        :placeholder="$t('INBOX_MGMT.ADD.MICROSOFT.EMAIL_PLACEHOLDER')"
      />
      <woot-submit-button
        icon="brand-twitter"
        type="submit"
        :button-text="$t('INBOX_MGMT.ADD.MICROSOFT.SIGN_IN')"
        :loading="isRequestingAuthorization"
      />
    </form>
  </div>
</template>
