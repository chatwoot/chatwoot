<template>
  <div class="flex-1 px-1 overflow-auto">
    <form class="space-y-8" @submit.prevent="submit">
      <section class="space-y-3">
        <form-input
          v-model.trim="credentials.email"
          type="email"
          name="email_address"
          :class="{ error: $v.credentials.email.$error }"
          :label="$t('REGISTER.EMAIL.LABEL')"
          :placeholder="$t('REGISTER.EMAIL.PLACEHOLDER')"
          :has-error="$v.credentials.email.$error"
          :error-message="$t('REGISTER.EMAIL.ERROR')"
          @blur="$v.credentials.email.$touch"
        />
        <form-input
          v-model.trim="credentials.password"
          type="password"
          name="password"
          :class="{ error: $v.credentials.password.$error }"
          :label="$t('LOGIN.PASSWORD.LABEL')"
          :placeholder="$t('SET_NEW_PASSWORD.PASSWORD.PLACEHOLDER')"
          :has-error="$v.credentials.password.$error"
          :error-message="passwordErrorText"
          @blur="$v.credentials.password.$touch"
        />
      </section>
      <div v-if="globalConfig.hCaptchaSiteKey" class="mb-3">
        <vue-hcaptcha
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
      <submit-button
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

<script>
import { required, minLength, email } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import alertMixin from 'shared/mixins/alertMixin';
import { ONBOARDING_START_URL } from 'dashboard/constants/globals';
import VueHcaptcha from '@hcaptcha/vue-hcaptcha';
import FormInput from 'dashboard/components/form/Input.vue';
import SubmitButton from '../../../../../components/Button/SubmitButton.vue';
import { isValidPassword } from 'shared/helpers/Validators';
import GoogleOAuthButton from '../../../../../components/GoogleOauth/Button.vue';
import { register } from '../../../../../api/auth';
var CompanyEmailValidator = require('company-email-validator');

export default {
  components: {
    FormInput,
    GoogleOAuthButton,
    SubmitButton,
    VueHcaptcha,
  },
  mixins: [globalConfigMixin, alertMixin],
  data() {
    return {
      credentials: {
        email: 'Testing123@shivam.dev',
        password: 'Testing123@shivam.dev',
        hCaptchaClientResponse: '',
      },
      didCaptchaReset: false,
      isSignupInProgress: false,
      error: '',
    };
  },
  validations: {
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
        minLength: minLength(6),
      },
    },
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
      const { password } = this.$v.credentials;
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
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.resetCaptcha();
        return;
      }
      this.isSignupInProgress = true;
      try {
        await register(this.credentials);
        window.location = ONBOARDING_START_URL;
      } catch (error) {
        let errorMessage =
          error?.message || this.$t('REGISTER.API.ERROR_MESSAGE');
        this.resetCaptcha();
        this.showAlert(errorMessage);
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
  },
};
</script>
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
