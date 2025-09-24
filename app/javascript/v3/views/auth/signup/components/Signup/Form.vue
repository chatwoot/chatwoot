<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import VueHcaptcha from '@hcaptcha/vue3-hcaptcha';
import FormInput from '../../../../../components/Form/Input.vue';
import SubmitButton from '../../../../../components/Button/SubmitButton.vue';
import { isValidPassword } from 'shared/helpers/Validators';
import GoogleOAuthButton from '../../../../../components/GoogleOauth/Button.vue';
import { register } from '../../../../../api/auth';
// import * as CompanyEmailValidator from 'company-email-validator';

export default {
  components: {
    FormInput,
    GoogleOAuthButton,
    SubmitButton,
    VueHcaptcha,
  },
  mixins: [globalConfigMixin],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      credentials: {
        accountName: '',
        fullName: '',
        email: '',
        phoneNumber: '',
        password: '',
        hCaptchaClientResponse: '',
      },
      didCaptchaReset: false,
      isSignupInProgress: false,
      error: '',
      showPassword: false,
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
          // businessEmailValidator(value) {
          //   return CompanyEmailValidator.isCompanyEmail(value);
          // },
        },
        phoneNumber: {
          required,
          minLength: minLength(10),
        },
        password: {
          required,
          isValidPassword,
          minLength: minLength(6),
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
      if (!password.minLength) {
        return this.$t('REGISTER.PASSWORD.ERROR');
      }
      if (!password.isValidPassword) {
        return this.$t('REGISTER.PASSWORD.IS_INVALID_PASSWORD');
      }
      return '';
    },
    showGoogleOAuth() {
      return Boolean(window.chatwootConfig.googleOAuthClientId);
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
        // Redirect to OTP verification page instead of dashboard
        this.$router.push({
          name: 'auth_verify_email',
          query: { email: this.credentials.email }
        });
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
    },
    resetCaptcha() {
      if (!this.globalConfig.hCaptchaSiteKey) {
        return;
      }
      this.$refs.hCaptcha.reset();
      this.credentials.hCaptchaClientResponse = '';
      this.didCaptchaReset = true;
    },
    showHidePassword() {
      this.showPassword = !this.showPassword;
    },
  },
};
</script>

<template>
  <div class="flex-1 px-1 overflow-auto">
    <form class="space-y-3" @submit.prevent="submit">
      <div class="grid grid-cols-1 gap-2">
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
        v-model="credentials.phoneNumber"
        type="tel"
        name="phone_number"
        :class="{ error: v$.credentials.phoneNumber.$error }"
        :label="$t('REGISTER.PHONE_NUMBER.LABEL')"
        :placeholder="$t('REGISTER.PHONE_NUMBER.PLACEHOLDER')"
        :has-error="v$.credentials.phoneNumber.$error"
        :error-message="$t('REGISTER.PHONE_NUMBER.ERROR')"
        @blur="v$.credentials.phoneNumber.$touch"
      />
      <div class="relative">
        <FormInput
          v-model="credentials.password"
          :type="showPassword ? 'text' : 'password'"
          name="password"
          :class="{ error: v$.credentials.password.$error }"
          :label="$t('REGISTER.PASSWORD.LABEL')"
          :placeholder="$t('REGISTER.PASSWORD.PLACEHOLDER')"
          :has-error="v$.credentials.password.$error"
          :error-message="$t('REGISTER.PASSWORD.IS_INVALID_PASSWORD')"
          @blur="v$.credentials.password.$touch"
        />
        <button
          type="button"
          :class="`w-8 h-12 absolute right-0 ${v$.credentials.password.$error ? 'bottom-12' : 'bottom-0'}`"
          @click="showHidePassword"
        >
          <fluent-icon
            v-if="!showPassword"
            icon="eye-hide"
            size="18"
            class="text-slate-900 dark:text-slate-50"
          />
          <fluent-icon
            v-if="showPassword"
            icon="eye-show"
            size="18"
            class="text-slate-900 dark:text-slate-50"
          />
        </button>
      </div>
      <div v-if="globalConfig.hCaptchaSiteKey" class="mb-3">
        <VueHcaptcha
          ref="hCaptcha"
          :class="{ error: !hasAValidCaptcha && didCaptchaReset }"
          :sitekey="globalConfig.hCaptchaSiteKey"
          @verify="onRecaptchaVerified"
        />
        <span
          v-if="!hasAValidCaptcha && didCaptchaReset"
          class="text-xs text-red-400"
        >
          {{ $t('SET_NEW_PASSWORD.CAPTCHA.ERROR') }}
        </span>
      </div>
      <SubmitButton
        :button-text="$t('REGISTER.SUBMIT')"
        :disabled="isSignupInProgress || !hasAValidCaptcha"
        :loading="isSignupInProgress"
        icon-class="arrow-chevron-right"
      />
    </form>
    <GoogleOAuthButton v-if="showGoogleOAuth" class="flex-col-reverse">
      {{ $t('REGISTER.OAUTH.GOOGLE_SIGNUP') }}
    </GoogleOAuthButton>
    <p
      class="text-sm mb-1 mt-5 text-slate-800 dark:text-woot-50 [&>a]:text-woot-500 [&>a]:font-medium [&>a]:hover:text-woot-600"
      v-html="termsLink"
    />
  </div>
</template>

<style scoped lang="scss">
.h-captcha--box {
  &::v-deep .error {
    iframe {
      border: 1px solid var(--r-500);
      border-radius: var(--border-radius-normal);
    }
  }
}
</style>
