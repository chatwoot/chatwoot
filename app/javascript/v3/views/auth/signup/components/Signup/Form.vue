<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import VueHcaptcha from '@hcaptcha/vue3-hcaptcha';
import SimpleDivider from '../../../../../components/Divider/SimpleDivider.vue';
import FormInput from '../../../../../components/Form/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { isValidPassword } from 'shared/helpers/Validators';
import GoogleOAuthButton from '../../../../../components/GoogleOauth/Button.vue';
import { register } from '../../../../../api/auth';
import * as CompanyEmailValidator from 'company-email-validator';

export default {
  components: {
    FormInput,
    GoogleOAuthButton,
    NextButton,
    SimpleDivider,
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
          minLength: minLength(6),
        },
        confirmPassword: {
          required,
          minLength: minLength(6),
          isEqPassword(value) {
            return value === this.credentials.password;
          },
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
    passwordErrorText() {
      const { password } = this.v$.credentials;
      if (!password.$error) {
        return '';
      }
      if (password.minLength.$invalid) {
        return this.$t('REGISTER.PASSWORD.ERROR');
      }
      if (password.isValidPassword.$invalid) {
        return this.$t('REGISTER.PASSWORD.IS_INVALID_PASSWORD');
      }
      return '';
    },
    confirmPasswordErrorText() {
      const { confirmPassword } = this.v$.credentials;
      if (!confirmPassword.$error) {
        return '';
      }
      if (confirmPassword.isEqPassword.$invalid) {
        return this.$t('REGISTER.CONFIRM_PASSWORD.ERROR');
      }
      return '';
    },
    showGoogleOAuth() {
      return Boolean(window.chatwootConfig.googleOAuthClientId);
    },
    isFormValid() {
      return !this.v$.$invalid && this.hasAValidCaptcha;
    },
    passwordRequirements() {
      const password = this.credentials.password;
      return {
        length: password.length >= 6,
        uppercase: /[A-Z]/.test(password),
        lowercase: /[a-z]/.test(password),
        number: /[0-9]/.test(password),
        special: /[!@#$%^&*()_+\-=[\]{}|'"/\\.,`<>:;?~]/.test(password),
      };
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
      if (!this.globalConfig.hCaptchaSiteKey) {
        return;
      }
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
        :error-message="passwordErrorText"
        @blur="v$.credentials.password.$touch"
      />
      <div class="text-xs text-slate-600 dark:text-slate-400 mb-2 space-y-1">
        <p class="font-medium">{{ $t('REGISTER.PASSWORD.REQUIREMENTS') }}</p>
        <ul class="space-y-1">
          <li class="flex items-center">
            <span
              :class="
                passwordRequirements.length
                  ? 'text-green-500'
                  : 'text-slate-400'
              "
            >
              {{ passwordRequirements.length ? '✓' : '○' }}
            </span>
            <span class="ml-2">
              {{ $t('REGISTER.PASSWORD.REQUIREMENTS_LENGTH') }}
            </span>
          </li>
          <li class="flex items-center">
            <span
              :class="
                passwordRequirements.uppercase
                  ? 'text-green-500'
                  : 'text-slate-400'
              "
            >
              {{ passwordRequirements.uppercase ? '✓' : '○' }}
            </span>
            <span class="ml-2">
              {{ $t('REGISTER.PASSWORD.REQUIREMENTS_UPPERCASE') }}
            </span>
          </li>
          <li class="flex items-center">
            <span
              :class="
                passwordRequirements.lowercase
                  ? 'text-green-500'
                  : 'text-slate-400'
              "
            >
              {{ passwordRequirements.lowercase ? '✓' : '○' }}
            </span>
            <span class="ml-2">
              {{ $t('REGISTER.PASSWORD.REQUIREMENTS_LOWERCASE') }}
            </span>
          </li>
          <li class="flex items-center">
            <span
              :class="
                passwordRequirements.number
                  ? 'text-green-500'
                  : 'text-slate-400'
              "
            >
              {{ passwordRequirements.number ? '✓' : '○' }}
            </span>
            <span class="ml-2">
              {{ $t('REGISTER.PASSWORD.REQUIREMENTS_NUMBER') }}
            </span>
          </li>
          <li class="flex items-center">
            <span
              :class="
                passwordRequirements.special
                  ? 'text-green-500'
                  : 'text-slate-400'
              "
            >
              {{ passwordRequirements.special ? '✓' : '○' }}
            </span>
            <span class="ml-2">
              {{ $t('REGISTER.PASSWORD.REQUIREMENTS_SPECIAL') }}
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
