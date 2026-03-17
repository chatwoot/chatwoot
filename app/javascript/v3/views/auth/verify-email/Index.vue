<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { resendConfirmationEmail } from '../../../api/auth';

const props = defineProps({
  email: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();

const isResendingEmail = ref(false);

const handleResendEmail = async () => {
  isResendingEmail.value = true;
  try {
    await resendConfirmationEmail({ email: props.email });
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
  <div
    class="flex flex-col justify-center w-full min-h-screen py-12 bg-n-brand/5 dark:bg-n-background sm:px-6 lg:px-8"
  >
    <div
      class="bg-white shadow sm:mx-auto sm:w-full sm:max-w-lg dark:bg-n-solid-2 p-11 sm:shadow-lg sm:rounded-lg"
    >
      <h1
        class="mb-1 text-2xl font-medium tracking-tight text-left text-n-slate-12"
      >
        {{ $t('REGISTER.VERIFY_EMAIL.TITLE') }}
      </h1>
      <p
        class="mb-4 text-sm font-normal leading-6 tracking-normal text-n-slate-11"
      >
        {{ $t('REGISTER.VERIFY_EMAIL.DESCRIPTION', { email: props.email }) }}
      </p>
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
      <p class="mt-4 -mb-1 text-sm text-n-slate-11">
        {{ $t('COMMON.BACK_TO') }}
        <router-link to="/auth/login" class="text-link text-n-brand">
          {{ $t('COMMON.LOGIN') }}.
        </router-link>
      </p>
    </div>
  </div>
</template>
