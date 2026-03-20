<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import Cookies from 'js-cookie';
import { useAlert } from 'dashboard/composables';
import { clearCookiesOnLogout } from 'dashboard/store/utils/api';
import NextButton from 'dashboard/components-next/button/Button.vue';
import wootAPI from '../../../api/apiClient';

const { t } = useI18n();
const router = useRouter();

const authData = (() => {
  const cookie = Cookies.get('cw_d_session_info');
  return cookie ? JSON.parse(cookie) : null;
})();

if (!authData) {
  router.push({ name: 'login' });
}

const email = authData?.uid || '';
const isResendingEmail = ref(false);

const authHeaders = authData
  ? {
      'access-token': authData['access-token'],
      'token-type': authData['token-type'],
      client: authData.client,
      expiry: authData.expiry,
      uid: authData.uid,
    }
  : {};

const handleResendEmail = async () => {
  isResendingEmail.value = true;
  try {
    await wootAPI.post(
      '/api/v1/profile/resend_confirmation',
      {},
      { headers: authHeaders }
    );
    useAlert(t('REGISTER.VERIFY_EMAIL.RESEND_SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.message || t('REGISTER.VERIFY_EMAIL.RESEND_ERROR');
    useAlert(errorMessage);
  } finally {
    isResendingEmail.value = false;
  }
};

const handleLogout = async () => {
  try {
    await wootAPI.delete('auth/sign_out', { headers: authHeaders });
  } finally {
    clearCookiesOnLogout();
  }
};
</script>

<template>
  <main
    class="flex flex-col w-full min-h-screen py-20 bg-n-brand/5 dark:bg-n-background sm:px-6 lg:px-8"
  >
    <section
      class="bg-white shadow sm:mx-auto mt-11 sm:w-full sm:max-w-lg dark:bg-n-solid-2 p-11 sm:shadow-lg sm:rounded-lg"
    >
      <div class="mb-6">
        <h2 class="text-2xl font-semibold text-n-slate-12">
          {{ $t('REGISTER.VERIFY_EMAIL.TITLE') }}
        </h2>
        <p class="mt-2 text-sm text-n-slate-11">
          {{ $t('REGISTER.VERIFY_EMAIL.DESCRIPTION', { email }) }}
        </p>
      </div>
      <div class="space-y-4">
        <NextButton
          lg
          type="button"
          data-testid="resend_email_button"
          class="w-full"
          :label="$t('REGISTER.VERIFY_EMAIL.RESEND')"
          :is-loading="isResendingEmail"
          @click="handleResendEmail"
        />
      </div>
    </section>
    <div class="mt-6 text-center">
      <button
        class="text-sm text-n-slate-8 hover:text-n-slate-10"
        @click="handleLogout"
      >
        {{ $t('LOGIN.BACK_TO_LOGIN') }}
      </button>
    </div>
  </main>
</template>
