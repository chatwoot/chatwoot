<template>
  <div>
    <form class="space-y-8" @submit.prevent="submit">
      <section class="space-y-3">
        <form-input
          v-model="credentials.email"
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
          v-model="credentials.password"
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
      <!-- min height will ensure there is no layout shift -->
      <div v-if="globalConfig.hCaptchaSiteKey" class="mb-3 min-h-[5rem]">
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
    <div class="text-sm text-slate-800 dark:text-woot-50">
      <span>{{ $t('REGISTER.HAVE_AN_ACCOUNT') }}</span>
      <router-link class="text-link" to="/app/login">
        {{
          useInstallationName($t('LOGIN.TITLE'), globalConfig.installationName)
        }}
      </router-link>
    </div>
  </div>
</template>

<script>
import { required, minLength, email } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import alertMixin from 'shared/mixins/alertMixin';
import VueHcaptcha from '@hcaptcha/vue-hcaptcha';
import FormInput from 'v3/components/Form/Input.vue';
import SubmitButton from 'v3/components/Button/SubmitButton.vue';
import { isValidPassword } from 'shared/helpers/Validators';
import GoogleOAuthButton from 'v3/components/GoogleOauth/Button.vue';
import { registerV2 } from 'v3/api/auth';
var CompanyEmailValidator = require('company-email-validator');

export const generateOnboardingUrl = accountId =>
  `/app/accounts/${accountId}/start/setup-profile`;

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
        email: '',
        password: '',
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
        const {
          data: { account_id: accountId },
        } = await registerV2(this.credentials);

        window.location = generateOnboardingUrl(accountId);
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
