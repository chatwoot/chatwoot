<script setup>
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'dashboard/composables/useI18n';
import googleClient from 'dashboard/api/channel/googleClient';
import SettingsSubPageHeader from '../../../SettingsSubPageHeader.vue';
import { useVuelidate } from '@vuelidate/core';
import { required, email } from '@vuelidate/validators';
import { reactive, ref } from 'vue';

const { t } = useI18n();

const state = reactive({
  email: '',
});

const rules = {
  email: {
    required,
    email,
  },
};

const v$ = useVuelidate(rules, state);
const isRequestingAuthorization = ref(false);

async function requestAuthorization() {
  try {
    v$.$touch();
    if (v$.$invalid) return;

    isRequestingAuthorization.value = true;
    const response = await googleClient.generateAuthorization({
      email: state.email,
    });
    const {
      data: { url },
    } = response;
    window.location.href = url;
  } catch (error) {
    useAlert(t('INBOX_MGMT.ADD.GOOGLE.ERROR_MESSAGE'));
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
      :header-title="$t('INBOX_MGMT.ADD.GOOGLE.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.GOOGLE.DESCRIPTION')"
    />
    <form class="mt-6" @submit.prevent="requestAuthorization">
      <woot-input
        v-model="state.email"
        type="text"
        :placeholder="$t('INBOX_MGMT.ADD.GOOGLE.EMAIL_PLACEHOLDER')"
        @blur="v$.email.$touch"
      />
      <woot-submit-button
        icon="brand-twitter"
        :button-text="$t('INBOX_MGMT.ADD.GOOGLE.SIGN_IN')"
        type="submit"
        :loading="isRequestingAuthorization"
      />
    </form>
  </div>
</template>
