<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import VueHcaptcha from '@hcaptcha/vue3-hcaptcha';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { resendConfirmation } from '../../../api/auth';

const props = defineProps({
  email: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
const router = useRouter();
const store = useStore();

if (!props.email) {
  router.push({ name: 'login' });
}

const globalConfig = computed(() => store.getters['globalConfig/get']);
const isResendingEmail = ref(false);
const hCaptcha = ref(null);
let captchaToken = '';

const performResend = async () => {
  isResendingEmail.value = true;
  try {
    await resendConfirmation({
      email: props.email,
      hCaptchaClientResponse: captchaToken,
    });
    useAlert(t('REGISTER.VERIFY_EMAIL.RESEND_SUCCESS'));
  } catch {
    useAlert(t('REGISTER.VERIFY_EMAIL.RESEND_ERROR'));
  } finally {
    isResendingEmail.value = false;
    captchaToken = '';
    if (globalConfig.value.hCaptchaSiteKey) {
      hCaptcha.value.reset();
    }
  }
};

const handleResendEmail = () => {
  if (isResendingEmail.value) return;
  if (globalConfig.value.hCaptchaSiteKey) {
    hCaptcha.value.execute();
  } else {
    performResend();
  }
};

const onCaptchaVerified = token => {
  captchaToken = token;
  performResend();
};

const onCaptchaError = () => {
  isResendingEmail.value = false;
  captchaToken = '';
  hCaptcha.value.reset();
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
        <VueHcaptcha
          v-if="globalConfig.hCaptchaSiteKey"
          ref="hCaptcha"
          size="invisible"
          :sitekey="globalConfig.hCaptchaSiteKey"
          @verify="onCaptchaVerified"
          @error="onCaptchaError"
          @expired="onCaptchaError"
          @challenge-expired="onCaptchaError"
          @closed="onCaptchaError"
        />
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
