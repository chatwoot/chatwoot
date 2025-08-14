<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import VueHcaptcha from '@hcaptcha/vue3-hcaptcha';
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
    showGoogleOAuth() {
      return Boolean(window.chatwootConfig.googleOAuthClientId);
    },
    isFormValid() {
      return !this.v$.$invalid && this.hasAValidCaptcha;
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
    <GoogleOAuthButton v-if="showGoogleOAuth" class="flex-col-reverse">
      {{ $t('REGISTER.OAUTH.GOOGLE_SIGNUP') }}
    </GoogleOAuthButton>
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
