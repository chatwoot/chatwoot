<template>
  <form class="login-box medium-4 column align-self-middle" v-on:submit.prevent="submit()">
    <h4>{{$t('RESET_PASSWORD.TITLE')}}</h4>
    <div class="column log-in-form">

      <label :class="{ 'error': $v.credentials.email.$error }">
        {{$t('RESET_PASSWORD.EMAIL.LABEL')}}
        <input type="text" v-bind:placeholder="$t('RESET_PASSWORD.EMAIL.PLACEHOLDER')" v-model.trim="credentials.email" @input="$v.credentials.email.$touch">
        <span class="message" v-if="$v.credentials.email.$error">
          {{$t('RESET_PASSWORD.EMAIL.ERROR')}}
        </span>
      </label>
      <woot-submit-button
        :disabled="$v.credentials.email.$invalid || resetPassword.showLoading"
        :button-text="$t('RESET_PASSWORD.SUBMIT')"
        :loading="resetPassword.showLoading"
        button-class="expanded"
      />
    </div>
  </form>
</template>

<script>
/* global bus */
import { required, minLength, email } from 'vuelidate/lib/validators';
import Auth from '../../api/auth';

export default {
  data() {
    return {
      // We need to initialize the component with any
      // properties that will be used in it
      credentials: {
        email: '',
      },
      resetPassword: {
        message: '',
        showLoading: false,
      },
      error: '',
    };
  },
  validations: {
    credentials: {
      email: {
        required,
        email,
        minLength: minLength(4),
      },
    },
  },
  methods: {
    showAlert(message) {
      // Reset loading, current selected agent
      this.resetPassword.showLoading = false;
      bus.$emit('newToastMessage', message);
    },
    submit() {
      this.resetPassword.showLoading = true;
      Auth.resetPassword(this.credentials)
        .then((res) => {
          let message = this.$t('RESET_PASSWORD.API.SUCCESS_MESSAGE');
          if (res.data && res.data.message) {
            message = res.data.message;
          }
          this.showAlert(message);
          window.location = '/login';
        })
        .catch(() => {
          this.showAlert(this.$t('RESET_PASSWORD.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>
