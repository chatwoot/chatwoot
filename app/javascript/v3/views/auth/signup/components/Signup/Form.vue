<script setup>
import { ref, computed, reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import FormInput from '../../../../../components/Form/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { isValidPassword } from 'shared/helpers/Validators';
import GoogleOAuthButton from '../../../../../components/GoogleOauth/Button.vue';
import { register } from '../../../../../api/auth';
import * as CompanyEmailValidator from 'company-email-validator';

const MIN_PASSWORD_LENGTH = 6;

const store = useStore();
const { t } = useI18n();

const hCaptcha = ref(null);
const isPasswordFocused = ref(false);
const isSignupInProgress = ref(false);

const credentials = reactive({
  email: '',
  password: '',
  hCaptchaClientResponse: '',
});

const rules = {
  credentials: {
    email: {
      required,
      email,
      businessEmailValidator(value) {
        return CompanyEmailValidator.isCompanyEmail(value);
      },
    },
    password: {
      required,
      isValidPassword,
      minLength: minLength(MIN_PASSWORD_LENGTH),
    },
  },
};

const v$ = useVuelidate(rules, { credentials });

const globalConfig = computed(() => store.getters['globalConfig/get']);

const termsLink = computed(() =>
  t('REGISTER.TERMS_ACCEPT')
    .replace('https://www.chatwoot.com/terms', globalConfig.value.termsURL)
    .replace(
      'https://www.chatwoot.com/privacy-policy',
      globalConfig.value.privacyURL
    )
);

const allowedLoginMethods = computed(
  () => window.chatwootConfig.allowedLoginMethods || ['email']
);

const showGoogleOAuth = computed(
  () =>
    allowedLoginMethods.value.includes('google_oauth') &&
    Boolean(window.chatwootConfig.googleOAuthClientId)
);

const isFormValid = computed(() => !v$.value.$invalid);

const performRegistration = async () => {
  isSignupInProgress.value = true;
  try {
    await register(credentials);
    window.location = DEFAULT_REDIRECT_URL;
  } catch (error) {
    const errorMessage = error?.message || t('REGISTER.API.ERROR_MESSAGE');
    if (globalConfig.value.hCaptchaSiteKey) {
      hCaptcha.value.reset();
      credentials.hCaptchaClientResponse = '';
    }
    useAlert(errorMessage);
  } finally {
    isSignupInProgress.value = false;
  }
};

const submit = () => {
  if (isSignupInProgress.value) return;
  v$.value.$touch();
  if (v$.value.$invalid) return;
  isSignupInProgress.value = true;
  if (globalConfig.value.hCaptchaSiteKey) {
    hCaptcha.value.execute();
  } else {
    performRegistration();
  }
};
</script>

<template>
  <form class="space-y-5" @submit.prevent="submit">
    <div class="space-y-4">
      <FormInput
        v-model="credentials.email"
        type="email"
        name="email_address"
        :class="{ error: v$.credentials.email.$error }"
        :label="$t('REGISTER.EMAIL.LABEL')"
        :placeholder="$t('REGISTER.EMAIL.PLACEHOLDER')"
        :has-error="v$.credentials.email.$error"
        :error-message="$t('REGISTER.EMAIL.ERROR')"
        @blur="v$.credentials.email.$touch"
      />

      <div class="relative">
        <FormInput
          v-model="credentials.password"
          type="password"
          name="password"
          :class="{ error: v$.credentials.password.$error }"
          :label="$t('LOGIN.PASSWORD.LABEL')"
          :placeholder="$t('SET_NEW_PASSWORD.PASSWORD.PLACEHOLDER')"
          :has-error="v$.credentials.password.$error"
          @focus="isPasswordFocused = true"
          @blur="
            isPasswordFocused = false;
            v$.credentials.password.$touch();
          "
        />
      </div>
    </div>

    <NextButton
      lg
      type="submit"
      data-testid="submit_button"
      class="w-full font-semibold tracking-wide shadow-md hover:shadow-lg"
      :label="$t('REGISTER.SUBMIT')"
      :disabled="isSignupInProgress || !isFormValid"
      :is-loading="isSignupInProgress"
    />
  </form>

  <GoogleOAuthButton v-if="showGoogleOAuth" class="mt-4">
    {{ $t('REGISTER.OAUTH.GOOGLE_SIGNUP') }}
  </GoogleOAuthButton>

  <p
    class="text-sm mt-6 mb-0 text-[#5f6b72] [&>a]:text-[#034d66] [&>a]:font-semibold [&>a]:hover:text-[#023e52]"
    v-html="termsLink"
  />
</template>
