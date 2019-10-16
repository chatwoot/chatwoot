<template>
  <div class="medium-12 column login">
    <div class="text-center medium-12 login__hero align-self-top">
      <img src="~dashboard/assets/images/woot-logo.svg" alt="Woot-logo" class="hero__logo" />
      <h2 class="hero__title">{{$t('LOGIN.TITLE')}}</h2>
    </div>
    <div class="row align-center">
      <div class="small-12 medium-4 column">
        <form class="login-box column align-self-top" v-on:submit.prevent="login()">
          <div class="column log-in-form">
            <!-- <h4 class="text-center">{{$t('LOGIN.TITLE')}}</h4> -->
            <label :class="{ 'error': $v.credentials.email.$error }">
              {{$t('LOGIN.EMAIL.LABEL')}}
              <input type="text" v-bind:placeholder="$t('LOGIN.EMAIL.PLACEHOLDER')" v-model.trim="credentials.email" @input="$v.credentials.email.$touch">
            </label>
            <label :class="{ 'error': $v.credentials.password.$error }">
              {{$t('LOGIN.PASSWORD.LABEL')}}
              <input type="password" v-bind:placeholder="$t('LOGIN.PASSWORD.PLACEHOLDER')" v-model.trim="credentials.password" @input="$v.credentials.password.$touch">
            </label>
            <woot-submit-button
              :disabled="$v.credentials.email.$invalid || $v.credentials.password.$invalid || loginApi.showLoading"
              :button-text="$t('LOGIN.SUBMIT')"
              :loading="loginApi.showLoading"
              button-class="large expanded"
            >
            </woot-submit-button>
            <!-- <input type="submit" class="button " v-on:click.prevent="login()" v-bind:value="" > -->
          </div>
        </form>
        <div class="column text-center sigin__footer">
          <p>
            <router-link to="auth/reset/password">
              {{$t('LOGIN.FORGOT_PASSWORD')}}
            </router-link>
          </p>
          <p>
            <router-link to="auth/signup">
              {{ $t('LOGIN.CREATE_NEW_ACCOUNT') }}
            </router-link>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
/* global bus */

import { required, email } from 'vuelidate/lib/validators';

import WootSubmitButton from '../../components/buttons/FormSubmitButton';
// import router from '../../routes';

export default {
  components: {
    WootSubmitButton,
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
  methods: {
    showAlert(message) {
      // Reset loading, current selected agent
      this.loginApi.showLoading = false;
      this.loginApi.message = message;
      bus.$emit('newToastMessage', this.loginApi.message);
    },
    login() {
      this.loginApi.showLoading = true;
      const credentials = {
        email: this.credentials.email,
        password: this.credentials.password,
      };
      this.$store
        .dispatch('login', credentials)
        .then(() => {
          this.showAlert(this.$t('LOGIN.API.SUCCESS_MESSAGE'));
        })
        .catch((response) => {
          if (response && response.status === 401) {
            this.showAlert(this.$t('LOGIN.API.UNAUTH'));
            return;
          }
          this.showAlert(this.$t('LOGIN.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>
