<template>
  <main class="medium-12 column login">
    <section class="text-center medium-12 login__hero align-self-top">
      <img
        :src="globalConfig.logo"
        :alt="globalConfig.installationName"
        class="hero__logo"
      />
      <h2 class="hero__title">
        {{
          useInstallationName($t('LOGIN.TITLE'), globalConfig.installationName)
        }}
      </h2>
    </section>
    <section class="row align-center">
      <div v-if="!email" class="small-12 medium-4 column">
        <div ref="loginBox" class="login-box column align-self-top">
          <form class="column log-in-form" @submit.prevent="login()">
            <label :class="{ error: $v.credentials.email.$error }">
              {{ $t('LOGIN.EMAIL.LABEL') }}
              <input
                v-model.trim="credentials.email"
                type="text"
                data-testid="email_input"
                :placeholder="$t('LOGIN.EMAIL.PLACEHOLDER')"
                @input="$v.credentials.email.$touch"
              />
            </label>
            <label :class="{ error: $v.credentials.password.$error }">
              {{ $t('LOGIN.PASSWORD.LABEL') }}
              <input
                v-model.trim="credentials.password"
                type="password"
                data-testid="password_input"
                :placeholder="$t('LOGIN.PASSWORD.PLACEHOLDER')"
                @input="$v.credentials.password.$touch"
              />
            </label>
            <woot-submit-button
              :disabled="
                $v.credentials.email.$invalid ||
                  $v.credentials.password.$invalid ||
                  loginApi.showLoading
              "
              :button-text="$t('LOGIN.SUBMIT')"
              :loading="loginApi.showLoading"
              button-class="large expanded"
            />
          </form>
          <template v-if="showGoogleOAuth">
            <div class="separator">
              OR
            </div>
            <a :href="getGoogleAuthUrl()">
              <button class="button large expanded button__google_login">
                <img
                  src="/assets/images/auth/google.svg"
                  alt="Google Logo"
                  class="icon"
                />
                {{ $t('LOGIN.OAUTH.GOOGLE_LOGIN') }}
              </button>
            </a>
          </template>
        </div>
        <div class="text-center column sigin__footer">
          <p v-if="!globalConfig.disableUserProfileUpdate">
            <router-link to="auth/reset/password">
              {{ $t('LOGIN.FORGOT_PASSWORD') }}
            </router-link>
          </p>
          <p v-if="showSignupLink()">
            <router-link to="auth/signup">
              {{ $t('LOGIN.CREATE_NEW_ACCOUNT') }}
            </router-link>
          </p>
        </div>
      </div>
      <woot-spinner v-else size="" />
    </section>
  </main>
</template>

<script>
import { required, email } from 'vuelidate/lib/validators';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import WootSubmitButton from 'components/buttons/FormSubmitButton';
import { mapGetters } from 'vuex';
import { parseBoolean } from 'helpers/string';

const ERROR_MESSAGES = {
  'oauth-no-user': 'LOGIN.OAUTH.NO_USER',
};

export default {
  components: {
    WootSubmitButton,
  },
  mixins: [globalConfigMixin],
  props: {
    ssoAuthToken: { type: String, default: '' },
    ssoAccountId: { type: String, default: '' },
    ssoConversationId: { type: String, default: '' },
    config: { type: String, default: '' },
    email: { type: String, default: '' },
    authError: { type: String, default: '' },
  },
  data() {
    return {
      // We need to initialize the component with any
      // properties that will be used in it
      credentials: {
        email: '',
        password: '',
      },
      loginApi: {
        message: '',
        showLoading: false,
      },
      error: '',
    };
  },
  validations: {
    credentials: {
      password: {
        required,
      },
      email: {
        required,
        email,
      },
    },
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
  },
  created() {
    if (this.ssoAuthToken) {
      this.login();
    }
    if (this.authError) {
      const message = ERROR_MESSAGES[this.authError] ?? 'LOGIN.API.UNAUTH';
      this.showAlert(this.$t(message));
      // wait for idle state
      window.requestIdleCallback(() => {
        // Remove the error query param from the url
        const { query } = this.$route;
        this.$router.replace({ query: { ...query, error: undefined } });
      });
    }
  },
  methods: {
    showAlert(message) {
      // Reset loading, current selected agent
      this.loginApi.showLoading = false;
      this.loginApi.message = message;
      bus.$emit('newToastMessage', this.loginApi.message);
    },
    getGoogleAuthUrl() {
      const baseUrl =
        'https://accounts.google.com/o/oauth2/auth/oauthchooseaccount';
      const clientId = window.chatwootConfig.googleOAuthClientId;
      const redirectUri = window.chatwootConfig.googleOAuthCallbackUrl;
      const responseType = 'code';
      const scope = 'email profile';

      // Build the query string
      const queryString = new URLSearchParams({
        client_id: clientId,
        redirect_uri: redirectUri,
        response_type: responseType,
        scope: scope,
      }).toString();

      // Construct the full URL
      return `${baseUrl}?${queryString}`;
    },
    showSignupLink() {
      return parseBoolean(window.chatwootConfig.signupEnabled);
    },
    showGoogleOAuth() {
      return parseBoolean(window.chatwootConfig.googleOAuthEnabled);
    },
    login() {
      this.loginApi.showLoading = true;
      const credentials = {
        email: this.email
          ? decodeURIComponent(this.email)
          : this.credentials.email,
        password: this.credentials.password,
        sso_auth_token: this.ssoAuthToken,
        ssoAccountId: this.ssoAccountId,
        ssoConversationId: this.ssoConversationId,
      };
      this.$store
        .dispatch('login', credentials)
        .then(() => {
          this.showAlert(this.$t('LOGIN.API.SUCCESS_MESSAGE'));
        })
        .catch(response => {
          // Reset URL Params if the authentication is invalid
          if (this.email) {
            window.location = '/app/login';
          }

          this.$refs.loginBox.classList.add('invalid');
          setTimeout(() => {
            this.$refs.loginBox.classList.remove('invalid');
          }, 500);

          if (response && response.status === 401) {
            const { errors } = response.data;
            const hasAuthErrorMsg =
              errors &&
              errors.length &&
              errors[0] &&
              typeof errors[0] === 'string';
            if (hasAuthErrorMsg) {
              this.showAlert(errors[0]);
            } else {
              this.showAlert(this.$t('LOGIN.API.UNAUTH'));
            }
            return;
          }
          this.showAlert(this.$t('LOGIN.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>

<style lang="scss" scoped>
.separator {
  display: flex;
  align-items: center;
  margin: 2rem 0rem;
  gap: 1rem;
  color: var(--s-300);
  font-size: var(--font-size-small);

  &::before,
  &::after {
    content: '';
    flex: 1;
    height: 1px;
    background: var(--s-100);
  }
}

.button__google_login {
  background: var(--white);
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  border: 1px solid var(--s-100);
  color: var(--b-800);
}

@media (prefers-reduced-motion: no-preference) {
  .login-box.invalid {
    animation: shake 0.5s linear;
  }
  @keyframes shake {
    8%,
    41% {
      -webkit-transform: translateX(-10px);
    }
    25%,
    58% {
      -webkit-transform: translateX(10px);
    }
    75% {
      -webkit-transform: translateX(-5px);
    }
    92% {
      -webkit-transform: translateX(5px);
    }
    0%,
    100% {
      -webkit-transform: translateX(0);
    }
  }
}
</style>
