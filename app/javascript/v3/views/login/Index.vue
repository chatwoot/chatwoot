<template>
  <main
    class="flex flex-col bg-woot-25 min-h-screen w-full py-20 sm:px-6 lg:px-8 dark:bg-slate-900"
  >
    <section class="max-w-5xl mx-auto">
      <img
        :src="globalConfig.logo"
        :alt="globalConfig.installationName"
        class="mx-auto h-8 w-auto block dark:hidden"
      />
      <img
        v-if="globalConfig.logoDark"
        :src="globalConfig.logoDark"
        :alt="globalConfig.installationName"
        class="mx-auto h-8 w-auto hidden dark:block"
      />
      <h2
        class="mt-6 text-center text-3xl font-medium text-slate-900 dark:text-woot-50"
      >
        {{
          useInstallationName($t('LOGIN.TITLE'), globalConfig.installationName)
        }}
      </h2>
      <p
        v-if="showSignupLink"
        class="mt-3 text-center text-sm text-slate-600 dark:text-slate-400"
      >
        {{ $t('COMMON.OR') }}
        <router-link to="auth/signup" class="text-link lowercase">
          {{ $t('LOGIN.CREATE_NEW_ACCOUNT') }}
        </router-link>
      </p>
    </section>
    <section
      class="bg-white shadow sm:mx-auto mt-11 sm:w-full sm:max-w-lg dark:bg-slate-800 p-11 sm:shadow-lg sm:rounded-lg"
      :class="{
        'mb-8 mt-15': !showGoogleOAuth,
        'animate-wiggle': loginApi.hasErrored,
      }"
    >
      <div v-if="!email">
        <GoogleOAuthButton v-if="showGoogleOAuth" />
        <form class="space-y-5" @submit.prevent="submitLogin">
          <form-input
            v-model.trim="credentials.email"
            name="email_address"
            type="text"
            data-testid="email_input"
            required
            :label="$t('LOGIN.EMAIL.LABEL')"
            :placeholder="$t('LOGIN.EMAIL.PLACEHOLDER')"
            :has-error="$v.credentials.email.$error"
            @input="$v.credentials.email.$touch"
          />
          <form-input
            v-model.trim="credentials.password"
            type="password"
            name="password"
            data-testid="password_input"
            required
            :label="$t('LOGIN.PASSWORD.LABEL')"
            :placeholder="$t('LOGIN.PASSWORD.PLACEHOLDER')"
            :has-error="$v.credentials.password.$error"
            @input="$v.credentials.password.$touch"
          >
            <p v-if="!globalConfig.disableUserProfileUpdate">
              <router-link to="auth/reset/password" class="text-link">
                {{ $t('LOGIN.FORGOT_PASSWORD') }}
              </router-link>
            </p>
          </form-input>
          <submit-button
            :disabled="loginApi.showLoading"
            :button-text="$t('LOGIN.SUBMIT')"
            :loading="loginApi.showLoading"
          />
        </form>
      </div>
      <div v-else class="flex items-center justify-center">
        <spinner color-scheme="primary" size="" />
      </div>
    </section>
  </main>
</template>

<script>
import { required, email } from 'vuelidate/lib/validators';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import SubmitButton from '../../components/Button/SubmitButton.vue';
import { mapGetters } from 'vuex';
import { parseBoolean } from '@chatwoot/utils';
import GoogleOAuthButton from '../../components/GoogleOauth/Button.vue';
import FormInput from '../../components/Form/Input.vue';
import { login } from '../../api/auth';
import Spinner from 'shared/components/Spinner.vue';
const ERROR_MESSAGES = {
  'no-account-found': 'LOGIN.OAUTH.NO_ACCOUNT_FOUND',
  'business-account-only': 'LOGIN.OAUTH.BUSINESS_ACCOUNTS_ONLY',
};

export default {
  components: {
    FormInput,
    GoogleOAuthButton,
    Spinner,
    SubmitButton,
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
        hasErrored: false,
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
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    showGoogleOAuth() {
      return Boolean(window.chatwootConfig.googleOAuthClientId);
    },
    showSignupLink() {
      return parseBoolean(window.chatwootConfig.signupEnabled);
    },
  },
  created() {
    if (this.ssoAuthToken) {
      this.submitLogin();
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
    submitLogin() {
      if (this.$v.credentials.email.$invalid && !this.email) {
        this.showAlert(this.$t('LOGIN.EMAIL.ERROR'));
        return;
      }

      this.loginApi.hasErrored = false;
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

      login(credentials)
        .then(() => {
          this.showAlert(this.$t('LOGIN.API.SUCCESS_MESSAGE'));
        })
        .catch(response => {
          // Reset URL Params if the authentication is invalid
          if (this.email) {
            window.location = '/app/login';
          }
          this.loginApi.hasErrored = true;
          this.showAlert(response?.message || this.$t('LOGIN.API.UNAUTH'));
        });
    },
  },
};
</script>
