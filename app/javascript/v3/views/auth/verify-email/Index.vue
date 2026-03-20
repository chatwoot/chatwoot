<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { getAuthData, getAuthHeaders } from '../../../helpers/AuthHelper';
import NextButton from 'dashboard/components-next/button/Button.vue';
import wootAPI from '../../../api/apiClient';

const { t } = useI18n();
const router = useRouter();

const authData = getAuthData();

if (!authData) {
  router.push({ name: 'login' });
}

const email = authData?.uid || '';
const isResendingEmail = ref(false);

onMounted(async () => {
  try {
    const { data } = await wootAPI.get('/api/v1/profile', {
      headers: getAuthHeaders(),
    });
    if (data.confirmed) {
      window.location = '/app/';
    }
  } catch {
    // if profile fetch fails, stay on the page
  }
});

const handleResendEmail = async () => {
  isResendingEmail.value = true;
  try {
    await wootAPI.post(
      '/api/v1/profile/resend_confirmation',
      {},
      { headers: getAuthHeaders() }
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
  </main>
</template>
