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
          {{ $t('REGISTER.VERIFY_EMAIL.DESCRIPTION', { email: props.email }) }}
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
      <router-link
        to="/auth/login"
        class="text-sm text-n-slate-10 hover:text-n-slate-11"
      >
        {{ $t('LOGIN.BACK_TO_LOGIN') }}
      </router-link>
    </div>
  </main>
</template>
