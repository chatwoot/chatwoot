<template>
  <div class="medium-12 column login"></div>
</template>

<script>
import { required, email } from 'vuelidate/lib/validators';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import WootSubmitButton from '../../components/buttons/FormSubmitButton';
import { mapGetters } from 'vuex';

export default {
  components: {
    WootSubmitButton,
  },
  mixins: [globalConfigMixin],
  props: {
    ssoAuthToken: { type: String, default: '' },
    redirectUrl: { type: String, default: '' },
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
  beforeMount() {
    this.$auth.loginWithRedirect();
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
        email: this.email ? this.email : this.credentials.email,
        password: this.credentials.password,
        sso_auth_token: this.ssoAuthToken,
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
