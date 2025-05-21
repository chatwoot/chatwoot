<script>
// utils and composables
import { login } from '../../api/auth';
import { mapGetters } from 'vuex';
import { parseBoolean } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';
import { required, email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';

// mixins
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

// components
import FormInput from '../../components/Form/Input.vue';
import GoogleOAuthButton from '../../components/GoogleOauth/Button.vue';
import Spinner from 'shared/components/Spinner.vue';
import SubmitButton from '../../components/Button/SubmitButton.vue';

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
    email: { type: String, default: '' },
    authError: { type: String, default: '' },
  },
  setup() {
    return { v$: useVuelidate() };
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
  validations() {
    return {
      credentials: {
        password: {
          required,
        },
        email: {
          required,
          email,
        },
      },
    };
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
      useAlert(this.$t(message));
      // wait for idle state
      this.requestIdleCallbackPolyfill(() => {
        // Remove the error query param from the url
        const { query } = this.$route;
        this.$router.replace({ query: { ...query, error: undefined } });
      });
    }
  },
  methods: {
    // TODO: Remove this when Safari gets wider support
    // Ref: https://caniuse.com/requestidlecallback
    //
    requestIdleCallbackPolyfill(callback) {
      if (window.requestIdleCallback) {
        window.requestIdleCallback(callback);
      } else {
        // Fallback for safari
        // Using a delay of 0 allows the callback to be executed asynchronously
        // in the next available event loop iteration, similar to requestIdleCallback
        setTimeout(callback, 0);
      }
    },
    showAlertMessage(message) {
      // Reset loading, current selected agent
      this.loginApi.showLoading = false;
      this.loginApi.message = message;
      useAlert(this.loginApi.message);
    },
    submitLogin() {
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
          this.showAlertMessage(this.$t('LOGIN.API.SUCCESS_MESSAGE'));
        })
        .catch(response => {
          // Reset URL Params if the authentication is invalid
          if (this.email) {
            window.location = '/app/login';
          }
          this.loginApi.hasErrored = true;
          this.showAlertMessage(
            response?.message || this.$t('LOGIN.API.UNAUTH')
          );
        });
    },
    submitFormLogin() {
      if (this.v$.credentials.email.$invalid && !this.email) {
        this.showAlertMessage(this.$t('LOGIN.EMAIL.ERROR'));
        return;
      }

      this.submitLogin();
    },
  },
};
</script>

<template>
  <main
    class="flex flex-col w-full min-h-screen py-20 bg-n-brand/5 dark:bg-n-background sm:px-6 lg:px-8"
  >
    <section class="max-w-5xl mx-auto">
      <img
        :src="globalConfig.logo"
        :alt="globalConfig.installationName"
        class="block w-auto h-8 mx-auto dark:hidden"
      />
      <img
        v-if="globalConfig.logoDark"
        :src="globalConfig.logoDark"
        :alt="globalConfig.installationName"
        class="hidden w-auto h-8 mx-auto dark:block"
      />
      <h2 class="mt-6 text-3xl font-medium text-center text-n-slate-12">
        {{
          useInstallationName($t('LOGIN.TITLE'), globalConfig.installationName)
        }}
      </h2>
      <p v-if="showSignupLink" class="mt-3 text-sm text-center text-n-slate-11">
        {{ $t('COMMON.OR') }}
        <router-link to="auth/signup" class="lowercase text-link text-n-brand">
          {{ $t('LOGIN.CREATE_NEW_ACCOUNT') }}
        </router-link>
      </p>
    </section>
    <section
      class="bg-white shadow sm:mx-auto mt-11 sm:w-full sm:max-w-lg dark:bg-n-solid-2 p-11 sm:shadow-lg sm:rounded-lg"
      :class="{
        'mb-8 mt-15': !showGoogleOAuth,
        'animate-wiggle': loginApi.hasErrored,
      }"
    >
      <div v-if="!email">
        <GoogleOAuthButton v-if="showGoogleOAuth" />
        <form class="space-y-5" @submit.prevent="submitFormLogin">
          <FormInput
            v-model="credentials.email"
            name="email_address"
            type="text"
            data-testid="email_input"
            :tabindex="1"
            required
            :label="$t('LOGIN.EMAIL.LABEL')"
            :placeholder="$t('LOGIN.EMAIL.PLACEHOLDER')"
            :has-error="v$.credentials.email.$error"
            @input="v$.credentials.email.$touch"
          />
          <FormInput
            v-model="credentials.password"
            type="password"
            name="password"
            data-testid="password_input"
            required
            :tabindex="2"
            :label="$t('LOGIN.PASSWORD.LABEL')"
            :placeholder="$t('LOGIN.PASSWORD.PLACEHOLDER')"
            :has-error="v$.credentials.password.$error"
            @input="v$.credentials.password.$touch"
          >
            <p v-if="!globalConfig.disableUserProfileUpdate">
              <router-link
                to="auth/reset/password"
                class="text-sm text-link"
                tabindex="4"
              >
                {{ $t('LOGIN.FORGOT_PASSWORD') }}
              </router-link>
            </p>
          </FormInput>
          <SubmitButton
            :disabled="loginApi.showLoading"
            :tabindex="3"
            :button-text="$t('LOGIN.SUBMIT')"
            :loading="loginApi.showLoading"
          />
        </form>
      </div>
      <div v-else class="flex items-center justify-center">
        <Spinner color-scheme="primary" size="" />
      </div>
    </section>
  </main>
</template>
