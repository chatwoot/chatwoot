<script>
// utils and composables
import { login } from '../../api/auth';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { required, email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { SESSION_STORAGE_KEYS } from 'dashboard/constants/sessionStorage';
import SessionStorage from 'shared/helpers/sessionStorage';
// components
import SimpleDivider from '../../components/Divider/SimpleDivider.vue';
import FormInput from '../../components/Form/Input.vue';
import GoogleOAuthButton from '../../components/GoogleOauth/Button.vue';
import Spinner from 'shared/components/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import MfaVerification from 'dashboard/components/auth/MfaVerification.vue';

const ERROR_MESSAGES = {
  'no-account-found': 'LOGIN.OAUTH.NO_ACCOUNT_FOUND',
  'business-account-only': 'LOGIN.OAUTH.BUSINESS_ACCOUNTS_ONLY',
  'saml-authentication-failed': 'LOGIN.SAML.API.ERROR_MESSAGE',
  'saml-not-enabled': 'LOGIN.SAML.API.ERROR_MESSAGE',
};

const IMPERSONATION_URL_SEARCH_KEY = 'impersonation';

export default {
  components: {
    FormInput,
    GoogleOAuthButton,
    Spinner,
    NextButton,
    SimpleDivider,
    MfaVerification,
    Icon,
  },
  props: {
    ssoAuthToken: { type: String, default: '' },
    ssoAccountId: { type: String, default: '' },
    ssoConversationId: { type: String, default: '' },
    email: { type: String, default: '' },
    authError: { type: String, default: '' },
  },
  setup() {
    return {
      v$: useVuelidate(),
    };
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
      mfaRequired: false,
      mfaToken: null,
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
    allowedLoginMethods() {
      return window.chatwootConfig.allowedLoginMethods || ['email'];
    },
    showGoogleOAuth() {
      return (
        this.allowedLoginMethods.includes('google_oauth') &&
        Boolean(window.chatwootConfig.googleOAuthClientId)
      );
    },
    showSignupLink() {
      return window.chatwootConfig.signupEnabled === 'true';
    },
    showSamlLogin() {
      return this.allowedLoginMethods.includes('saml');
    },
  },
  created() {
    if (this.ssoAuthToken) {
      this.submitLogin();
    }
    if (this.authError) {
      const messageKey = ERROR_MESSAGES[this.authError] ?? 'LOGIN.API.UNAUTH';
      // Use a method to get the translated text to avoid dynamic key warning
      const translatedMessage = this.getTranslatedMessage(messageKey);
      useAlert(translatedMessage);
      // wait for idle state
      this.requestIdleCallbackPolyfill(() => {
        // Remove the error query param from the url
        const { query } = this.$route;
        this.$router.replace({ query: { ...query, error: undefined } });
      });
    }
  },
  methods: {
    getTranslatedMessage(key) {
      // Avoid dynamic key warning by handling each case explicitly
      switch (key) {
        case 'LOGIN.OAUTH.NO_ACCOUNT_FOUND':
          return this.$t('LOGIN.OAUTH.NO_ACCOUNT_FOUND');
        case 'LOGIN.OAUTH.BUSINESS_ACCOUNTS_ONLY':
          return this.$t('LOGIN.OAUTH.BUSINESS_ACCOUNTS_ONLY');
        case 'LOGIN.API.UNAUTH':
        default:
          return this.$t('LOGIN.API.UNAUTH');
      }
    },
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
    handleImpersonation() {
      // Detects impersonation mode via URL and sets a session flag to prevent user settings changes during impersonation.
      const urlParams = new URLSearchParams(window.location.search);
      const impersonation = urlParams.get(IMPERSONATION_URL_SEARCH_KEY);
      if (impersonation) {
        SessionStorage.set(SESSION_STORAGE_KEYS.IMPERSONATION_USER, true);
      }
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
        .then(result => {
          // Check if MFA is required
          if (result?.mfaRequired) {
            this.loginApi.showLoading = false;
            this.mfaRequired = true;
            this.mfaToken = result.mfaToken;
            return;
          }

          this.handleImpersonation();
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
    handleMfaVerified() {
      // MFA verification successful, continue with login
      this.handleImpersonation();
      window.location = '/app';
    },
    handleMfaCancel() {
      // User cancelled MFA, reset state
      this.mfaRequired = false;
      this.mfaToken = null;
      this.credentials.password = '';
    },
  },
};
</script>

<template>
  <main
    class="flex min-h-screen w-full flex-col bg-n-brand/5 py-16 dark:bg-background sm:px-6 sm:py-20 md:py-24 lg:px-8"
  >
    <section class="mx-auto w-full max-w-5xl px-4 sm:px-0">
      <div class="flex flex-col items-center justify-center">
        <img
          :src="globalConfig.logoThumbnail"
          :alt="globalConfig.installationName"
          class="block h-24 w-auto shrink-0 sm:h-28 md:h-32"
        />
        <div
          class="flex flex-col items-center gap-0.5 text-center sm:items-start sm:text-left"
        >
          <span
            class="font-inter text-4xl font-bold uppercase leading-none tracking-tight text-transparent bg-gradient-to-r from-woot-500 via-secondary to-green-200 bg-clip-text sm:text-5xl"
          >
            {{ globalConfig.installationName }}
          </span>
        </div>
      </div>
    </section>

    <!-- MFA Verification Section -->
    <section v-if="mfaRequired" class="mt-12 sm:mt-14">
      <MfaVerification
        :mfa-token="mfaToken"
        @verified="handleMfaVerified"
        @cancel="handleMfaCancel"
      />
    </section>

    <!-- Regular Login Section -->
    <section
      v-else
      class="mt-12 overflow-hidden rounded-xl bg-white px-8 pb-0 pt-8 shadow-sm ring-1 ring-n-container dark:bg-surface-container dark:ring-0 dark:shadow-xl sm:mx-auto sm:mt-14 sm:w-full sm:max-w-lg sm:px-10 sm:pt-10"
      :class="{
        'mb-10 sm:mb-12': !showGoogleOAuth,
        'animate-wiggle': loginApi.hasErrored,
      }"
    >
      <div v-if="!email">
        <h1
          class="mb-2 text-[2rem] font-bold leading-[1.15] tracking-tight text-balance text-n-slate-12 dark:text-on-surface sm:text-[2.125rem]"
        >
          {{ $t('LOGIN.WELCOME_BACK') }}
        </h1>
        <p
          class="max-w-md text-sm leading-relaxed text-n-slate-11 dark:text-on-surface-variant"
        >
          {{
            $t('LOGIN.SIGN_IN_SUBTITLE', {
              productName: globalConfig.installationName,
            })
          }}
        </p>
        <div class="mb-6 flex flex-col gap-3 sm:mb-8 sm:gap-4">
          <GoogleOAuthButton v-if="showGoogleOAuth" />
          <div v-if="showSamlLogin" class="text-center">
            <router-link
              to="/app/login/sso"
              class="inline-flex w-full items-center justify-center rounded-lg bg-n-background px-4 py-3 shadow-sm ring-1 ring-inset ring-n-container transition-colors duration-200 hover:bg-n-alpha-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-secondary dark:bg-n-solid-3 dark:ring-n-container dark:hover:bg-n-alpha-2"
            >
              <Icon
                icon="i-lucide-lock-keyhole"
                class="size-5 text-n-slate-11 dark:text-on-surface-variant"
              />
              <span
                class="ml-2 text-base font-medium text-n-slate-12 dark:text-on-surface"
              >
                {{ $t('LOGIN.SAML.LABEL') }}
              </span>
            </router-link>
          </div>
          <SimpleDivider
            v-if="showGoogleOAuth || showSamlLogin"
            :label="$t('COMMON.OR')"
            class="uppercase"
          />
        </div>
        <form class="space-y-6" @submit.prevent="submitFormLogin">
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
                class="text-sm text-link underline-offset-2 transition-opacity hover:opacity-90 dark:text-secondary"
                tabindex="4"
              >
                {{ $t('LOGIN.FORGOT_PASSWORD') }}
              </router-link>
            </p>
          </FormInput>
          <NextButton
            lg
            type="submit"
            data-testid="submit_button"
            class="mt-1 w-full"
            :tabindex="3"
            :label="$t('LOGIN.SUBMIT')"
            :disabled="loginApi.showLoading"
            :is-loading="loginApi.showLoading"
          />
        </form>
      </div>
      <div v-else class="flex items-center justify-center pb-10">
        <Spinner color-scheme="primary" size="" />
      </div>
      <div
        v-if="showSignupLink && !email"
        class="mt-8 pb-8 pt-1 text-center text-xs leading-relaxed text-n-slate-11 dark:text-on-surface-variant sm:mt-10 sm:pb-10 sm:pt-2 sm:text-sm"
      >
        <div
          aria-hidden="true"
          class="mx-auto mb-5 h-px w-[min(10rem,62%)] max-w-full bg-gradient-to-r from-transparent via-n-container to-transparent opacity-80 dark:via-outline-variant sm:mb-6 sm:w-[min(12rem,58%)]"
        />
        <span class="text-n-slate-11 dark:text-on-surface-variant">
          {{ $t('LOGIN.NO_ACCOUNT_PROMPT') }}
        </span>
        {{ ' ' }}
        <router-link
          to="auth/signup"
          class="font-semibold text-n-brand underline-offset-4 transition-opacity hover:opacity-90 hover:underline dark:text-secondary"
        >
          {{ $t('LOGIN.SIGN_UP') }}
        </router-link>
      </div>
    </section>
  </main>
</template>
