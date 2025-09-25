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
      showPassword: false,
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
    showHidePassword() {
      this.showPassword = !this.showPassword;
    },
  },
};

</script>

<template>
  <main class="bg-background flex items-center justify-center p-4">
    <img src="v3/assets/images/Mascot-Laptop.png" alt="Mascot" class="z-50 absolute bottom-0 right-2/3 h-[500px]"/>
    <div class="w-full max-w-md">
      <div class="text-center mb-4">
        <div class="inline-flex items-center justify-center w-16 h-16">
          <img
            :src="globalConfig.logo"
            :alt="globalConfig.installationName"
            class="block w-auto h-46 mx-auto"
          />
        </div>
        
        <h1 class="text-3xl font-bold text-slate-900 dark:text-white mb-2">
          {{
            useInstallationName(
              $t('LOGIN.TITLE'),
              globalConfig.installationName
            )
          }}
        </h1>
        
        <p class="text-slate-600 dark:text-slate-400 text-sm">
          {{
            useInstallationName(
              $t('LOGIN.SUBTITLE'),
              globalConfig.installationName
            )
          }}
        </p>
      </div>

      <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-xl border border-emerald-200 dark:border-slate-700 p-6">
        <section
          :class="{
            'animate-wiggle': loginApi.hasErrored,
          }"
        >
          <div v-if="!email">
            <div v-if="showGoogleOAuth">
              <GoogleOAuthButton/>
            </div>
            
            <form class="space-y-4" @submit.prevent="submitFormLogin">
              <div>
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
                  class="text-slate-900 dark:text-white bg-slate-50 dark:bg-slate-700 border-slate-200 dark:border-slate-600 focus:border-emerald-500 focus:ring-emerald-500"
                />
              </div>
              
              <div class="relative">
                <FormInput
                  v-model="credentials.password"
                  :type="showPassword ? 'text' : 'password'"
                  name="password"
                  data-testid="password_input"
                  required
                  :tabindex="2"
                  :label="$t('LOGIN.PASSWORD.LABEL')"
                  :placeholder="$t('LOGIN.PASSWORD.PLACEHOLDER')"
                  :has-error="v$.credentials.password.$error"
                  @input="v$.credentials.password.$touch"
                  class="text-slate-900 dark:text-white bg-slate-50 dark:bg-slate-700 border-slate-200 dark:border-slate-600 focus:border-emerald-500 focus:ring-emerald-500"
                />
                
                <button
                  type="button"
                  class="w-8 h-12 absolute bottom-0 right-0"
                  @click="showHidePassword"
                >
                  <fluent-icon
                    v-if="!showPassword"
                    icon="eye-hide"
                    size="18"
                    class="text-slate-900 dark:text-slate-50"
                  />
                  <fluent-icon
                    v-if="showPassword"
                    icon="eye-show"
                    size="18"
                    class="text-slate-500 dark:text-slate-400"
                  />
                </button>
              </div>
              
              <div
                v-if="!globalConfig.disableUserProfileUpdate"
                class="text-right"
              >
                <router-link
                  to="auth/reset/password"
                  class="text-sm text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 dark:hover:text-emerald-300 font-medium transition-colors"
                  tabindex="4"
                >
                  {{ $t('LOGIN.FORGOT_PASSWORD') }}
                </router-link>
              </div>
              
              <div class="pt-2">
                <SubmitButton
                  :disabled="loginApi.showLoading"
                  :tabindex="3"
                  :button-text="$t('LOGIN.SUBMIT')"
                  :loading="loginApi.showLoading"
                  class="w-full bg-emerald-600 hover:bg-emerald-700 focus:ring-emerald-500 text-white font-medium py-3 px-4 rounded-xl transition-colors"
                />
              </div>
            </form>
          </div>
          
          <div v-else class="flex items-center justify-center py-8">
            <Spinner color-scheme="primary" size="" />
          </div>
        </section>
        
        <div
          v-if="showSignupLink"
          class="mt-6 pt-6 border-t border-slate-600 dark:border-slate-400 text-center"
        >
          <p class="text-sm text-slate-600 dark:text-slate-400">
            {{ $t('LOGIN.DONT_HAVE_ACCOUNT') }}
            <router-link 
              to="auth/signup" 
              class="text-woot-500 dark:hover:text-emerald-300 font-medium transition-colors ml-1"
            >
              {{ $t('LOGIN.CREATE_NEW_ACCOUNT') }}
            </router-link>
          </p>
        </div>
      </div>
    </div>
  </main>
</template>

<style scoped>
.bg-background {
  background: linear-gradient(
    to bottom right,
    rgba(255, 250, 199, 0.4),       
    rgba(217, 255, 228, 0.3),      
    rgba(34, 197, 94, 0.1)  
  );
}

.dark .bg-background {
  background: linear-gradient(
    to bottom right,
    rgba(15, 23, 42, 0.95),
    rgba(30, 41, 59, 0.9)
  );
}
</style>

