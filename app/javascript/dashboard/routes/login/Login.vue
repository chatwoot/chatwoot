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
        <div class="login-box column align-self-top">
          <GoogleOAuthButton
            v-if="showGoogleOAuth()"
            button-size="large"
            class="oauth-reverse"
          />
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
import { parseBoolean } from '@chatwoot/utils';
import GoogleOAuthButton from '../../components/ui/Auth/GoogleOAuthButton.vue';

const ERROR_MESSAGES = {
  'no-account-found': 'LOGIN.OAUTH.NO_ACCOUNT_FOUND',
  'business-account-only': 'LOGIN.OAUTH.BUSINESS_ACCOUNTS_ONLY',
};

export default {
  components: {
    WootSubmitButton,
    GoogleOAuthButton,
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
    showSignupLink() {
      return parseBoolean(window.chatwootConfig.signupEnabled);
    },
    showGoogleOAuth() {
      return Boolean(window.chatwootConfig.googleOAuthClientId);
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
.oauth-reverse {
  display: flex;
  flex-direction: column-reverse;
}
</style>
