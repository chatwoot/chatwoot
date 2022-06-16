<template>
  <form
    class="login-box medium-4 column align-self-middle"
    @submit.prevent="login()"
  >
    <div class="column log-in-form">
      <h4>{{ $t('SET_NEW_PASSWORD.TITLE') }}</h4>
      <label :class="{ error: $v.credentials.password.$error }">
        {{ $t('LOGIN.PASSWORD.LABEL') }}
        <input
          v-model.trim="credentials.password"
          type="password"
          :placeholder="$t('SET_NEW_PASSWORD.PASSWORD.PLACEHOLDER')"
          @input="$v.credentials.password.$touch"
        />
        <span v-if="$v.credentials.password.$error" class="message">
          {{ $t('SET_NEW_PASSWORD.PASSWORD.ERROR') }}
        </span>
      </label>
      <label :class="{ error: $v.credentials.confirmPassword.$error }">
        {{ $t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.LABEL') }}
        <input
          v-model.trim="credentials.confirmPassword"
          type="password"
          :placeholder="$t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.PLACEHOLDER')"
          @input="$v.credentials.confirmPassword.$touch"
        />
        <span v-if="$v.credentials.confirmPassword.$error" class="message">
          {{ $t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.ERROR') }}
        </span>
      </label>
      <woot-submit-button
        :disabled="
          $v.credentials.password.$invalid ||
            $v.credentials.confirmPassword.$invalid ||
            newPasswordAPI.showLoading
        "
        :button-text="$t('SET_NEW_PASSWORD.SUBMIT')"
        :loading="newPasswordAPI.showLoading"
        button-class="expanded"
      />
      <!-- <input type="submit" class="button " v-on:click.prevent="login()" v-bind:value="" > -->
    </div>
  </form>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import Auth from '../../api/auth';

import WootSubmitButton from '../../components/buttons/FormSubmitButton';
import { DEFAULT_REDIRECT_URL } from '../../constants';

export default {
  components: {
    WootSubmitButton,
  },
  props: {
    resetPasswordToken: { type: String, default: '' },
    redirectUrl: { type: String, default: '' },
    config: { type: String, default: '' },
  },
  data() {
    return {
      // We need to initialize the component with any
      // properties that will be used in it
      credentials: {
        confirmPassword: '',
        password: '',
      },
      newPasswordAPI: {
        message: '',
        showLoading: false,
      },
      error: '',
    };
  },
  mounted() {
    // If url opened without token
    // redirect to login
    if (!this.resetPasswordToken) {
      window.location = DEFAULT_REDIRECT_URL;
    }
  },
  validations: {
    credentials: {
      password: {
        required,
        minLength: minLength(6),
      },
      confirmPassword: {
        required,
        minLength: minLength(6),
        isEqPassword(value) {
          if (value !== this.credentials.password) {
            return false;
          }
          return true;
        },
      },
    },
  },
  methods: {
    showAlert(message) {
      // Reset loading, current selected agent
      this.newPasswordAPI.showLoading = false;
      bus.$emit('newToastMessage', message);
    },
    login() {
      this.newPasswordAPI.showLoading = true;
      const credentials = {
        confirmPassword: this.credentials.confirmPassword,
        password: this.credentials.password,
        resetPasswordToken: this.resetPasswordToken,
      };
      Auth.setNewPassword(credentials)
        .then(res => {
          if (res.status === 200) {
            window.location = DEFAULT_REDIRECT_URL;
          }
        })
        .catch(error => {
          let errorMessage = this.$t('SET_NEW_PASSWORD.API.ERROR_MESSAGE');
          if (error?.data?.message) {
            errorMessage = error.data.message;
          }
          this.showAlert(errorMessage);
        });
    },
  },
};
</script>
