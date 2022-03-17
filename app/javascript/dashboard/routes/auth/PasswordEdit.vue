<template>
  <div class="password-edit flex-divided-view">
    <div class="form--wrap w-full">
      <auth-header
        :title="$t('SET_NEW_PASSWORD.TITLE')"
        :sub-title="$t('SET_NEW_PASSWORD.DESCRIPTION')"
      />
      <form class="" @submit.prevent="login()">
        <div class="input-wrap">
          <auth-input
            v-model.trim="credentials.password"
            type="password"
            :placeholder="$t('SET_NEW_PASSWORD.PASSWORD.PLACEHOLDER')"
            icon-name="lock-closed"
            :class="{ error: $v.credentials.password.$error }"
            :label="$t('LOGIN.PASSWORD.LABEL')"
            :error="
              $v.credentials.password.$error
                ? $t('SET_NEW_PASSWORD.PASSWORD.ERROR')
                : ''
            "
            @input="$v.credentials.password.$touch"
            @blur="$v.credentials.password.$touch"
          />
          <auth-input
            v-model.trim="credentials.confirmPassword"
            type="password"
            icon-name="lock-shield"
            :class="{ error: $v.credentials.confirmPassword.$error }"
            :label="$t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.LABEL')"
            :placeholder="$t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.PLACEHOLDER')"
            :error="
              $v.credentials.confirmPassword.$error
                ? $t('SET_NEW_PASSWORD.CONFIRM_PASSWORD.ERROR')
                : ''
            "
            @blur="$v.credentials.confirmPassword.$touch"
            @input="$v.credentials.confirmPassword.$touch"
          />
        </div>
        <auth-submit-button
          :label="$t('SET_NEW_PASSWORD.SUBMIT')"
          :is-disabled="
            $v.credentials.password.$invalid ||
              $v.credentials.confirmPassword.$invalid ||
              newPasswordAPI.showLoading
          "
          :is-loading="newPasswordAPI.showLoading"
          icon="arrow-chevron-right"
          @click="login()"
        />
        <!-- <input type="submit" class="button " v-on:click.prevent="login()" v-bind:value="" > -->
      </form>
    </div>
  </div>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import Auth from '../../api/auth';
import AuthInput from './components/AuthInput';
import AuthHeader from 'dashboard/routes/auth/components/AuthHeader';
import AuthSubmitButton from './components/AuthSubmitButton';

import { DEFAULT_REDIRECT_URL } from '../../constants';

export default {
  components: {
    AuthInput,
    AuthHeader,
    AuthSubmitButton,
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
<style lang="scss" scoped>
.password-edit {
  flex-direction: column;
  margin: var(--space-larger) 0;
}

.input-wrap {
  padding-bottom: var(--space-one);
}
</style>
