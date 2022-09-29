<template>
  <div class="row auth-screen--view align-center">
    <div class="login-form--wrap flex-divided-view">
      <div class="form--wrap w-full">
        <auth-header
          :title="
            useInstallationName(
              $t('LOGIN.TITLE'),
              globalConfig.installationName
            )
          "
          :sub-title="$t('LOGIN.DESCRIPTION')"
        />
        <div v-if="!email" class="w-full">
          <form class="" @submit.prevent="login()">
            <div>
              <auth-input
                v-model.trim="credentials.email"
                :class="{ error: $v.credentials.email.$error }"
                :label="$t('LOGIN.EMAIL.LABEL')"
                icon-name="mail"
                type="email"
                :placeholder="$t('LOGIN.EMAIL.PLACEHOLDER')"
                @blur="$v.credentials.email.$touch"
              />
              <auth-input
                v-model.trim="credentials.password"
                :class="{ error: $v.credentials.password.$error }"
                :label="$t('LOGIN.PASSWORD.LABEL')"
                icon-name="lock-closed"
                type="password"
                :placeholder="$t('LOGIN.PASSWORD.PLACEHOLDER')"
                @blur="$v.credentials.password.$touch"
              />
            </div>
            <auth-submit-button
              :label="$t('LOGIN.SUBMIT')"
              :is-disabled="
                $v.credentials.email.$invalid ||
                  $v.credentials.password.$invalid ||
                  loginApi.showLoading
              "
              :is-loading="loginApi.showLoading"
              icon="arrow-chevron-right"
              @click="login()"
            />
          </form>
          <div class="column text-center auth-screen--footer">
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
      </div>
    </div>
    <auth-right-screen />
  </div>
</template>

<script>
import { required, email } from 'vuelidate/lib/validators';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import { mapGetters } from 'vuex';
import AuthHeader from 'dashboard/routes/auth/components/AuthHeader';
import AuthRightScreen from 'dashboard/routes/auth/components/AuthRightScreen';
import AuthInput from 'dashboard/routes/auth/components/AuthInput';
import AuthSubmitButton from 'dashboard/routes/auth/components/AuthSubmitButton';

export default {
  components: {
    AuthHeader,
    AuthRightScreen,
    AuthInput,
    AuthSubmitButton,
  },
  mixins: [globalConfigMixin],
  props: {
    ssoAuthToken: { type: String, default: '' },
    ssoAccountId: { type: String, default: '' },
    ssoConversationId: { type: String, default: '' },
    config: { type: String, default: '' },
    email: { type: String, default: '' },
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
  },
  methods: {
    showAlert(message) {
      // Reset loading, current selected agent
      this.loginApi.showLoading = false;
      this.loginApi.message = message;
      bus.$emit('newToastMessage', this.loginApi.message);
    },
    showSignupLink() {
      return window.chatwootConfig.signupEnabled === 'true';
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
.login-form--wrap {
  flex-direction: column;
  margin: var(--space-medium) 0;
}

@media screen and (max-width: 1200px) {
  .login-form--wrap {
    margin: var(--space-larger) 0;
  }
}
</style>
