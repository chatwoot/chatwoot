<template>
  <div class="medium-10 column signup">
    <div class="text-center medium-12 signup--hero">
      <img
        :src="globalConfig.logo"
        :alt="globalConfig.installationName"
        class="hero--logo"
      />
      <h2 class="hero--title">
        {{ $t('REGISTER.TRY_WOOT') }}
      </h2>
    </div>
    <div class="row align-center">
      <div class="small-12 medium-6 large-5 column">
        <form class="signup--box login-box" @submit.prevent="submit">
          <woot-input
            v-model="credentials.fullName"
            :class="{ error: $v.credentials.fullName.$error }"
            :label="$t('REGISTER.FULL_NAME.LABEL')"
            :placeholder="$t('REGISTER.FULL_NAME.PLACEHOLDER')"
            :error="
              $v.credentials.fullName.$error
                ? $t('REGISTER.FULL_NAME.ERROR')
                : ''
            "
            @blur="$v.credentials.fullName.$touch"
          />
          <woot-input
            v-model.trim="credentials.email"
            type="email"
            :class="{ error: $v.credentials.email.$error }"
            :label="$t('REGISTER.EMAIL.LABEL')"
            :placeholder="$t('REGISTER.EMAIL.PLACEHOLDER')"
            :error="
              $v.credentials.email.$error ? $t('REGISTER.EMAIL.ERROR') : ''
            "
            @blur="$v.credentials.email.$touch"
          />
          <woot-input
            v-model="credentials.accountName"
            :class="{ error: $v.credentials.accountName.$error }"
            :label="$t('REGISTER.ACCOUNT_NAME.LABEL')"
            :placeholder="$t('REGISTER.ACCOUNT_NAME.PLACEHOLDER')"
            :error="
              $v.credentials.accountName.$error
                ? $t('REGISTER.ACCOUNT_NAME.ERROR')
                : ''
            "
            @blur="$v.credentials.accountName.$touch"
          />
          <woot-input
            v-model.trim="credentials.password"
            type="password"
            :class="{ error: $v.credentials.password.$error }"
            :label="$t('LOGIN.PASSWORD.LABEL')"
            :placeholder="$t('SET_NEW_PASSWORD.PASSWORD.PLACEHOLDER')"
            :error="
              $v.credentials.password.$error
                ? $t('SET_NEW_PASSWORD.PASSWORD.ERROR')
                : ''
            "
            @blur="$v.credentials.password.$touch"
          />

          <woot-input
            v-model.trim="credentials.confirmPassword"
            type="password"
            :class="{ error: $v.credentials.confirmPassword.$error }"
            :label="$t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.LABEL')"
            :placeholder="$t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.PLACEHOLDER')"
            :error="
              $v.credentials.confirmPassword.$error
                ? $t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.ERROR')
                : ''
            "
            @blur="$v.credentials.confirmPassword.$touch"
          />
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
          <woot-submit-button
            :disabled="isSignupInProgress || !hasAValidCaptcha"
            :button-text="$t('REGISTER.SUBMIT')"
            :loading="isSignupInProgress"
            button-class="large expanded"
          >
          </woot-submit-button>
          <p class="accept--terms" v-html="termsLink"></p>
        </form>
        <div class="column text-center sigin--footer">
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
export default {
  components: {
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
        confirmPassword: '',
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
        minLength: minLength(6),
      },
      confirmPassword: {
        required,
        isEqPassword(value) {
          if (value !== this.credentials.password) {
            return false;
          }
          return true;
        },
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
.signup {
  .signup--hero {
    margin-bottom: var(--space-larger);

    .hero--logo {
      width: 180px;
    }

    .hero--title {
      margin-top: var(--space-large);
      font-weight: var(--font-weight-light);
    }
  }

  .signup--box {
    padding: var(--space-large);

    label {
      font-size: var(--font-size-default);
      color: var(--b-600);

      input {
        padding: var(--space-slab);
        height: var(--space-larger);
        font-size: var(--font-size-default);
      }
    }
  }

  .sigin--footer {
    padding: var(--space-medium);
    font-size: var(--font-size-default);

    > a {
      font-weight: var(--font-weight-bold);
    }
  }

  .accept--terms {
    font-size: var(--font-size-small);
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
}
</style>
