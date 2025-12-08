<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email, sameAs } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
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

export default {
  components: {
    FormInput,
    GoogleOAuthButton,
    NextButton,
    SimpleDivider,
    Icon,
    VueHcaptcha,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      credentials: {
        accountName: '',
        fullName: '',
        email: '',
        password: '',
        confirmPassword: '',
        hCaptchaClientResponse: '',
      },
      didCaptchaReset: false,
      isSignupInProgress: false,
      error: '',
    };
  },
  validations() {
    return {
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
        confirmPassword: {
          required,
          minLength: minLength(MIN_PASSWORD_LENGTH),
          sameAsPassword: sameAs(this.credentials.password),
        },
      },
    };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    termsLink() {
      return this.$t('REGISTER.TERMS_ACCEPT')
        .replace('https://www.chatwoot.com/terms', this.globalConfig.termsURL)
        .replace(
          'https://www.chatwoot.com/privacy-policy',
          this.globalConfig.privacyURL
        );
    },
    hasAValidCaptcha() {
      if (this.globalConfig.hCaptchaSiteKey) {
        return !!this.credentials.hCaptchaClientResponse;
      }
      return true;
    },
    confirmPasswordErrorText() {
      const { confirmPassword } = this.v$.credentials;
      if (!confirmPassword.$error) return '';
      if (confirmPassword.sameAsPassword.$invalid) {
        return this.$t('REGISTER.CONFIRM_PASSWORD.ERROR');
      }
      return '';
    },
    allowedLoginMethods() {
      return window.chatwootConfig.allowedLoginMethods || ['email'];
    },
    showGoogleOAuth() {
      return (
        this.allowedLoginMethods.includes('google_oauth') &&
        Boolean(window.chatwootConfig.googleOAuthClientId)
      );
    },
    isFormValid() {
      return !this.v$.$invalid && this.hasAValidCaptcha;
    },
    passwordRequirements() {
      const password = this.credentials.password || '';
      return {
        length: password.length >= MIN_PASSWORD_LENGTH,
        uppercase: /[A-Z]/.test(password),
        lowercase: /[a-z]/.test(password),
        number: /[0-9]/.test(password),
        special: SPECIAL_CHAR_REGEX.test(password),
      };
    },
    passwordRequirementItems() {
      const reqs = this.passwordRequirements;
      return [
        {
          id: 'length',
          met: reqs.length,
          label: this.$t('REGISTER.PASSWORD.REQUIREMENTS_LENGTH', {
            min: MIN_PASSWORD_LENGTH,
          }),
        },
        {
          id: 'uppercase',
          met: reqs.uppercase,
          label: this.$t('REGISTER.PASSWORD.REQUIREMENTS_UPPERCASE'),
        },
        {
          id: 'lowercase',
          met: reqs.lowercase,
          label: this.$t('REGISTER.PASSWORD.REQUIREMENTS_LOWERCASE'),
        },
        {
          id: 'number',
          met: reqs.number,
          label: this.$t('REGISTER.PASSWORD.REQUIREMENTS_NUMBER'),
        },
        {
          id: 'special',
          met: reqs.special,
          label: this.$t('REGISTER.PASSWORD.REQUIREMENTS_SPECIAL'),
        },
      ];
    },
    passwordRequirementsMet() {
      return Object.values(this.passwordRequirements).every(Boolean);
    },
  },
  methods: {
    async submit() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        this.resetCaptcha();
        return;
      }
      this.isSignupInProgress = true;
      try {
        await register(this.credentials);
        window.location = DEFAULT_REDIRECT_URL;
      } catch (error) {
        let errorMessage =
          error?.message || this.$t('REGISTER.API.ERROR_MESSAGE');
        this.resetCaptcha();
        useAlert(errorMessage);
      } finally {
        this.isSignupInProgress = false;
      }
    },
    onRecaptchaVerified(token) {
      this.credentials.hCaptchaClientResponse = token;
      this.didCaptchaReset = false;
      this.v$.$touch();
    },
    resetCaptcha() {
      if (!this.globalConfig.hCaptchaSiteKey) return;
      this.$refs.hCaptcha.reset();
      this.credentials.hCaptchaClientResponse = '';
      this.didCaptchaReset = true;
    },
  },
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
        @blur="v$.credentials.password.$touch"
      />
      <div
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
      <FormInput
        v-model="credentials.confirmPassword"
        type="password"
        name="confirm_password"
        :class="{ error: v$.credentials.confirmPassword.$error }"
        :label="$t('REGISTER.CONFIRM_PASSWORD.LABEL')"
        :placeholder="$t('REGISTER.CONFIRM_PASSWORD.PLACEHOLDER')"
        :has-error="v$.credentials.confirmPassword.$error"
        :error-message="confirmPasswordErrorText"
        @blur="v$.credentials.confirmPassword.$touch"
      />
      <div v-if="globalConfig.hCaptchaSiteKey" class="mb-3">
        <VueHcaptcha
          ref="hCaptcha"
          :class="{ error: !hasAValidCaptcha && didCaptchaReset }"
          :sitekey="globalConfig.hCaptchaSiteKey"
          @verify="onRecaptchaVerified"
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
        v-if="showGoogleOAuth"
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
