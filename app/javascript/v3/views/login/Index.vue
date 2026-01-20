<script>
// utils and composables
import { login } from '../../api/auth';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { required, email } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';
import { SESSION_STORAGE_KEYS } from 'dashboard/constants/sessionStorage';
import SessionStorage from 'shared/helpers/sessionStorage';
import { useBranding } from 'shared/composables/useBranding';

// components
import SimpleDivider from '../../components/Divider/SimpleDivider.vue';
import FormInput from '../../components/Form/Input.vue';
import GoogleOAuthButton from '../../components/GoogleOauth/Button.vue';
import Spinner from 'shared/components/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import MfaVerification from 'dashboard/components/auth/MfaVerification.vue';
import LanguageSelect from '../../components/Form/LanguageSelect.vue';

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
    LanguageSelect,
  },
  props: {
    ssoAuthToken: { type: String, default: '' },
    ssoAccountId: { type: String, default: '' },
    ssoConversationId: { type: String, default: '' },
    email: { type: String, default: '' },
    authError: { type: String, default: '' },
  },
  setup() {
    const { replaceInstallationName } = useBranding();
    return {
      replaceInstallationName,
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
      selectedLocale: this.getBrowserDefaultLocale(),
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
    getBrowserDefaultLocale() {
      const enabledLanguages = window.chatwootConfig?.enabledLanguages || [];
      const browserLang = navigator.language || navigator.userLanguage || 'en';
      const normalizedLang = browserLang.replace('-', '_');

      // Try exact match first (e.g., pt_BR)
      const exactMatch = enabledLanguages.find(
        lang => lang.iso_639_1_code === normalizedLang
      );
      if (exactMatch) return exactMatch.iso_639_1_code;

      // Try base language match (e.g., pt)
      const baseLang = normalizedLang.split('_')[0];
      const baseMatch = enabledLanguages.find(
        lang => lang.iso_639_1_code === baseLang
      );
      if (baseMatch) return baseMatch.iso_639_1_code;

      // Default to current i18n locale or English
      return window.chatwootConfig?.selectedLocale || 'en';
    },
    onLocaleChange(locale) {
      this.selectedLocale = locale;
      // Update the page locale immediately
      this.$root.$i18n.locale = locale;
    },
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
  <div class="w-full h-full bg-n-background">
    <div class="flex h-full min-h-screen items-center">
      <div
        class="flex-1 min-h-[640px] inline-flex items-center h-full justify-center overflow-auto py-6"
      >
        <div class="px-8 max-w-[560px] w-full overflow-auto">
          <div class="mb-4 flex items-start justify-between">
            <div>
              <img
                :src="globalConfig.logo"
                :alt="globalConfig.installationName"
                class="block w-auto h-8 dark:hidden"
              />
              <img
                v-if="globalConfig.logoDark"
                :src="globalConfig.logoDark"
                :alt="globalConfig.installationName"
                class="hidden w-auto h-8 dark:block"
              />
              <h2
                class="mt-6 text-3xl font-medium text-left mb-7 text-n-slate-12"
              >
                {{ replaceInstallationName($t('LOGIN.TITLE')) }}
              </h2>
            </div>
            <div class="flex-shrink-0 w-40">
              <LanguageSelect
                v-model="selectedLocale"
                @change="onLocaleChange"
              />
            </div>
          </div>

          <!-- MFA Verification Section -->
          <section v-if="mfaRequired">
            <MfaVerification
              :mfa-token="mfaToken"
              @verified="handleMfaVerified"
              @cancel="handleMfaCancel"
            />
          </section>

          <!-- Regular Login Section -->
          <section
            v-else
            :class="{
              'animate-wiggle': loginApi.hasErrored,
            }"
          >
            <div v-if="!email">
              <div class="flex flex-col gap-4">
                <GoogleOAuthButton v-if="showGoogleOAuth" />
                <div v-if="showSamlLogin" class="text-center">
                  <router-link
                    to="/app/login/sso"
                    class="inline-flex justify-center w-full px-4 py-3 items-center bg-n-background dark:bg-n-solid-3 rounded-md shadow-sm ring-1 ring-inset ring-n-container dark:ring-n-container focus:outline-offset-0 hover:bg-n-alpha-2 dark:hover:bg-n-alpha-2"
                  >
                    <Icon
                      icon="i-lucide-lock-keyhole"
                      class="size-5 text-n-slate-11"
                    />
                    <span class="ml-2 text-base font-medium text-n-slate-12">
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
                <NextButton
                  lg
                  type="submit"
                  data-testid="submit_button"
                  class="w-full"
                  :tabindex="3"
                  :label="$t('LOGIN.SUBMIT')"
                  :disabled="loginApi.showLoading"
                  :is-loading="loginApi.showLoading"
                />
              </form>
            </div>
            <div v-else class="flex items-center justify-center">
              <Spinner color-scheme="primary" size="" />
            </div>
          </section>

          <div v-if="showSignupLink" class="px-1 text-sm text-n-slate-12 mt-4">
            {{ $t('COMMON.OR') }}
            <router-link
              to="auth/signup"
              class="lowercase text-link text-n-brand ml-1"
            >
              {{ $t('LOGIN.CREATE_NEW_ACCOUNT') }}
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
