<template>
  <!-- <div class="row signup"> -->
  <div class="sign-up flex-divided-view">
    <div class="form--wrap w-full">
      <auth-header
        :title="$t('REGISTER.TITLE')"
        :sub-title="$t('REGISTER.TRY_WOOT')"
      />

      <div class="w-ful column">
        <form @submit.prevent="submit">
          <div class="input-wrap">
            <auth-input
              v-model="credentials.fullName"
              :class="{ error: $v.credentials.fullName.$error }"
              :label="$t('REGISTER.FULL_NAME.LABEL')"
              icon-name="person"
              :placeholder="$t('REGISTER.FULL_NAME.PLACEHOLDER')"
              :error="
                $v.credentials.fullName.$error
                  ? $t('REGISTER.FULL_NAME.ERROR')
                  : ''
              "
              @blur="$v.credentials.fullName.$touch"
            />
            <auth-input
              v-model.trim="credentials.email"
              type="email"
              :class="{ error: $v.credentials.email.$error }"
              icon-name="mail"
              :label="$t('REGISTER.EMAIL.LABEL')"
              :placeholder="$t('REGISTER.EMAIL.PLACEHOLDER')"
              :error="
                $v.credentials.email.$error ? $t('REGISTER.EMAIL.ERROR') : ''
              "
              @blur="$v.credentials.email.$touch"
            />
            <auth-input
              v-model="credentials.accountName"
              :class="{ error: $v.credentials.accountName.$error }"
              icon-name="person-account"
              :label="$t('REGISTER.ACCOUNT_NAME.LABEL')"
              :placeholder="$t('REGISTER.ACCOUNT_NAME.PLACEHOLDER')"
              :error="
                $v.credentials.accountName.$error
                  ? $t('REGISTER.ACCOUNT_NAME.ERROR')
                  : ''
              "
              @blur="$v.credentials.accountName.$touch"
            />
            <auth-input
              v-model.trim="credentials.password"
              type="password"
              :class="{ error: $v.credentials.password.$error }"
              icon-name="lock-closed"
              :label="$t('LOGIN.PASSWORD.LABEL')"
              :placeholder="$t('SET_NEW_PASSWORD.PASSWORD.PLACEHOLDER')"
              :error="passwordErrorText"
              @blur="$v.credentials.password.$touch"
            />
          </div>
          <div v-if="globalConfig.hCaptchaSiteKey" class="h-captcha--box">
            <vue-hcaptcha
              ref="hCaptcha"
              :class="{ error: !hasAValidCaptcha && didCaptchaReset }"
              :sitekey="globalConfig.hCaptchaSiteKey"
              @verify="onRecaptchaVerified"
            />
            <span
              v-if="!hasAValidCaptcha && didCaptchaReset"
              class="captcha-error"
            >
              {{ $t('SET_NEW_PASSWORD.CAPTCHA.ERROR') }}
            </span>
          </div>
          <auth-submit-button
            :label="$t('REGISTER.SUBMIT')"
            :is-disabled="isSignupInProgress || !hasAValidCaptcha"
            :is-loading="isSignupInProgress"
            icon="arrow-chevron-right"
            @click="submit"
          />
          <p v-dompurify-html="termsLink" class="accept--terms" />
        </form>
        <div class="column text-center auth-screen--footer">
          <span>{{ $t('REGISTER.HAVE_AN_ACCOUNT') }}</span>
          <router-link to="/app/login">
            {{
              useInstallationName(
                $t('LOGIN.TITLE'),
                globalConfig.installationName
              )
            }}
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { required, minLength, email } from 'vuelidate/lib/validators';
import Auth from '../../api/auth';
import { mapGetters } from 'vuex';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import alertMixin from 'shared/mixins/alertMixin';
import { DEFAULT_REDIRECT_URL } from '../../constants';
import VueHcaptcha from '@hcaptcha/vue-hcaptcha';
import AuthInput from './components/AuthInput';
import AuthHeader from './components/AuthHeader';
import AuthSubmitButton from './components/AuthSubmitButton';
import { isValidPassword } from 'shared/helpers/Validators';
export default {
  components: {
    AuthInput,
    AuthHeader,
    AuthSubmitButton,
    VueHcaptcha,
  },
  mixins: [globalConfigMixin, alertMixin],
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
  validations: {
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
        const response = await Auth.register(this.credentials);
        if (response.status === 200) {
          window.location = DEFAULT_REDIRECT_URL;
        }
      } catch (error) {
        let errorMessage = this.$t('REGISTER.API.ERROR_MESSAGE');
        if (error.response && error.response.data.message) {
          this.resetCaptcha();
          errorMessage = error.response.data.message;
        }
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
.sign-up {
  margin: var(--space-medium) 0;
}

.input-wrap {
  padding-bottom: var(--space-slab);
}

.accept--terms {
  text-align: center;
  margin: var(--space-normal) 0 0 0;
}

.h-captcha--box {
  margin-bottom: var(--space-one);

  .captcha-error {
    color: var(--r-400);
    font-size: var(--font-size-small);
  }

  &::v-deep .error {
    iframe {
      border: 1px solid var(--r-500);
      border-radius: var(--border-radius-normal);
    }
  }
}

@media screen and (max-width: 1200px) {
  .sign-up {
    margin-top: var(--space-larger);
    width: 100%;
  }
}
</style>
