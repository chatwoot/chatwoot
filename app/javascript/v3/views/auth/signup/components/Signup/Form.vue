<script setup>
import { ref, reactive, computed } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email, sameAs } from '@vuelidate/validators';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import VueHcaptcha from '@hcaptcha/vue3-hcaptcha';
import SimpleDivider from '../../../../../components/Divider/SimpleDivider.vue';
import FormInput from '../../../../../components/Form/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { isValidPassword } from 'shared/helpers/Validators';
import GoogleOAuthButton from '../../../../../components/GoogleOauth/Button.vue';
import { register } from '../../../../../api/auth';
import * as CompanyEmailValidator from 'company-email-validator';

const MIN_PASSWORD_LENGTH = 6;
const SPECIAL_CHAR_REGEX = /[!@#$%^&*()_+\-=[\]{}|'"/\\.,`<>:;?~]/;

const store = useStore();
const { t } = useI18n();

const hCaptcha = ref(null);
const credentials = reactive({
  accountName: '',
  fullName: '',
  email: '',
  password: '',
  hCaptchaClientResponse: '',
});
const didCaptchaReset = ref(false);
const isSignupInProgress = ref(false);
const isPasswordFocused = ref(false);

const rules = computed(() => ({
  credentials: {
    accountName: {
      required,
      minLength: minLength(2),
    },
    fullName: {
      required,
      minLength: minLength(2),
    },
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
}));

const v$ = useVuelidate(rules, { credentials });

const globalConfig = computed(() => store.getters['globalConfig/get']);

const termsLink = computed(() => {
  return t('REGISTER.TERMS_ACCEPT')
    .replace('https://www.chatwoot.com/terms', globalConfig.value.termsURL)
    .replace(
      'https://www.chatwoot.com/privacy-policy',
      globalConfig.value.privacyURL
    );
});

const hasAValidCaptcha = computed(() => {
  if (globalConfig.value.hCaptchaSiteKey) {
    return !!credentials.hCaptchaClientResponse;
  }
  return true;
});

const showGoogleOAuth = computed(() => {
  return Boolean(window.chatwootConfig.googleOAuthClientId);
});

const isFormValid = computed(() => {
  return !v$.value.$invalid;
});

const passwordRequirements = computed(() => {
  const password = credentials.password || '';
  return {
    length: password.length >= MIN_PASSWORD_LENGTH,
    uppercase: /[A-Z]/.test(password),
    lowercase: /[a-z]/.test(password),
    number: /[0-9]/.test(password),
    special: SPECIAL_CHAR_REGEX.test(password),
  };
});

const passwordRequirementItems = computed(() => {
  const reqs = passwordRequirements.value;
  return [
    {
      id: 'length',
      met: reqs.length,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_LENGTH', {
        min: MIN_PASSWORD_LENGTH,
      }),
    },
    {
      id: 'uppercase',
      met: reqs.uppercase,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_UPPERCASE'),
    },
    {
      id: 'lowercase',
      met: reqs.lowercase,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_LOWERCASE'),
    },
    {
      id: 'number',
      met: reqs.number,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_NUMBER'),
    },
    {
      id: 'special',
      met: reqs.special,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_SPECIAL'),
    },
  ];
});

const passwordRequirementsMet = computed(() => {
  return Object.values(passwordRequirements.value).every(Boolean);
});

const resetCaptcha = () => {
  if (!globalConfig.value.hCaptchaSiteKey) return;
  hCaptcha.value.reset();
  credentials.hCaptchaClientResponse = '';
  didCaptchaReset.value = true;
};

const submit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    resetCaptcha();
    return;
  }

  // For invisible captcha, there is no user input. We have to execute it if when
  // the user submits the form. If 99.9% Passive mode is enabled, the users won't
  // be prompted to solve the captcha
  if (globalConfig.value.hCaptchaSiteKey && !credentials.hCaptchaClientResponse) {
    hCaptcha.value.execute();
    return;
  }

  isSignupInProgress.value = true;
  try {
    await register(credentials);
    window.location = DEFAULT_REDIRECT_URL;
  } catch (error) {
    let errorMessage = error?.message || t('REGISTER.API.ERROR_MESSAGE');
    resetCaptcha();
    useAlert(errorMessage);
  } finally {
    isSignupInProgress.value = false;
  }
};

const onRecaptchaVerified = (token) => {
  credentials.hCaptchaClientResponse = token;
  didCaptchaReset.value = false;
  v$.value.$touch();
  // Auto-submit after captcha verification for invisible mode
  submit();
};

const onCaptchaExpired = () => {
  credentials.hCaptchaClientResponse = '';
  didCaptchaReset.value = true;
};

const onCaptchaError = (error) => {
  credentials.hCaptchaClientResponse = '';
  didCaptchaReset.value = true;
  useAlert(t('SET_NEW_PASSWORD.CAPTCHA.ERROR'));
};

const handlePasswordBlur = () => {
  v$.value.credentials.password.$touch();
  // Delay hiding requirements to allow submit button click to register
  setTimeout(() => {
    isPasswordFocused.value = false;
  }, 150);
};
</script>

<template>
  <div class="flex-1 px-1 overflow-auto">
    <form class="space-y-3" @submit.prevent="submit">
      <div class="grid grid-cols-2 gap-2">
        <FormInput
          v-model="credentials.fullName"
          name="full_name"
          class="flex-1"
          :class="{ error: v$.credentials.fullName.$error }"
          :label="$t('REGISTER.FULL_NAME.LABEL')"
          :placeholder="$t('REGISTER.FULL_NAME.PLACEHOLDER')"
          :has-error="v$.credentials.fullName.$error"
          :error-message="$t('REGISTER.FULL_NAME.ERROR')"
          @blur="v$.credentials.fullName.$touch"
        />
        <FormInput
          v-model="credentials.accountName"
          name="account_name"
          class="flex-1"
          :class="{ error: v$.credentials.accountName.$error }"
          :label="$t('REGISTER.COMPANY_NAME.LABEL')"
          :placeholder="$t('REGISTER.COMPANY_NAME.PLACEHOLDER')"
          :has-error="v$.credentials.accountName.$error"
          :error-message="$t('REGISTER.COMPANY_NAME.ERROR')"
          @blur="v$.credentials.accountName.$touch"
        />
      </div>
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
      <FormInput
        v-model="credentials.password"
        type="password"
        name="password"
        :class="{ error: v$.credentials.password.$error }"
        :label="$t('LOGIN.PASSWORD.LABEL')"
        :placeholder="$t('SET_NEW_PASSWORD.PASSWORD.PLACEHOLDER')"
        :has-error="v$.credentials.password.$error"
        aria-describedby="password-requirements"
        @focus="isPasswordFocused = true"
        @blur="handlePasswordBlur"
      />
      <div
        class="grid transition-all duration-300 ease-out"
        :class="isPasswordFocused ? 'grid-rows-[1fr]' : 'grid-rows-[0fr]'"
      >
        <div class="overflow-hidden">
          <div
            v-show="isPasswordFocused"
            id="password-requirements"
            class="text-xs rounded-md px-4 py-3 outline outline-1 outline-n-weak bg-n-alpha-black2"
          >
            <ul role="list" class="grid grid-cols-2 gap-1">
              <li
                v-for="item in passwordRequirementItems"
                :key="item.id"
                class="inline-flex gap-1 items-start"
              >
                <Icon
                  class="flex-none flex-shrink-0 w-3 mt-0.5"
                  :icon="item.met ? 'i-lucide-circle-check-big' : 'i-lucide-circle'"
                  :class="item.met ? 'text-n-teal-10' : 'text-n-slate-10'"
                />

                <span :class="item.met ? 'text-n-slate-11' : 'text-n-slate-10'">
                  {{ item.label }}
                </span>
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div v-if="globalConfig.hCaptchaSiteKey" class="mb-3">
        <VueHcaptcha
          ref="hCaptcha"
          :class="{ error: !hasAValidCaptcha && didCaptchaReset }"
          :sitekey="globalConfig.hCaptchaSiteKey"
          size="invisible"
          @verify="onRecaptchaVerified"
          @expired="onCaptchaExpired"
          @challenge-expired="onCaptchaExpired"
          @error="onCaptchaError"
        />
        <span
          v-if="!hasAValidCaptcha && didCaptchaReset"
          class="text-xs text-n-ruby-9"
        >
          {{ $t('SET_NEW_PASSWORD.CAPTCHA.ERROR') }}
        </span>
      </div>
      <NextButton
        lg
        type="submit"
        data-testid="submit_button"
        class="w-full"
        icon="i-lucide-chevron-right"
        trailing-icon
        :label="$t('REGISTER.SUBMIT')"
        :disabled="isSignupInProgress || !isFormValid"
        :is-loading="isSignupInProgress"
      />
    </form>
    <div class="flex flex-col">
      <SimpleDivider
        v-if="showGoogleOAuth || showSamlLogin"
        :label="$t('COMMON.OR')"
        bg="bg-n-background"
        class="uppercase"
      />
      <GoogleOAuthButton v-if="showGoogleOAuth">
        {{ $t('REGISTER.OAUTH.GOOGLE_SIGNUP') }}
      </GoogleOAuthButton>
    </div>
    <p
      class="text-sm mb-1 mt-5 text-n-slate-12 [&>a]:text-n-brand [&>a]:font-medium [&>a]:hover:brightness-110"
      v-html="termsLink"
    />
  </div>
</template>

<style scoped lang="scss">
.h-captcha--box {
  &::v-deep .error {
    iframe {
      @apply rounded-md border border-n-ruby-8 dark:border-n-ruby-8;
    }
  }
}
</style>
