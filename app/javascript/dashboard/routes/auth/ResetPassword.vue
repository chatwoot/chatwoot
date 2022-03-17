<template>
  <div class="reset--password flex-divided-view">
    <div class="form--wrap w-full">
      <auth-header
        :title="$t('RESET_PASSWORD.TITLE')"
        :sub-title="$t('RESET_PASSWORD.DESCRIPTION')"
      />
      <form class="w-full" @submit.prevent="submit()">
        <div class="input-wrap">
          <auth-input
            v-model.trim="credentials.email"
            type="email"
            icon-name="mail"
            :class="{ error: $v.credentials.email.$error }"
            :label="$t('RESET_PASSWORD.EMAIL.LABEL')"
            :placeholder="$t('RESET_PASSWORD.EMAIL.PLACEHOLDER')"
            :error="
              $v.credentials.email.$error
                ? $t('RESET_PASSWORD.EMAIL.ERROR')
                : ''
            "
            @blur="$v.credentials.email.$touch"
          />
        </div>
        <auth-submit-button
          :label="$t('RESET_PASSWORD.SUBMIT')"
          :is-disabled="
            $v.credentials.email.$invalid || resetPassword.showLoading
          "
          :is-loading="resetPassword.showLoading"
          icon="arrow-chevron-right"
          @click="submit()"
        />
      </form>
    </div>
  </div>
</template>

<script>
import { required, minLength, email } from 'vuelidate/lib/validators';
import Auth from '../../api/auth';
import AuthInput from './components/AuthInput';
import AuthHeader from 'dashboard/routes/auth/components/AuthHeader';
import AuthSubmitButton from './components/AuthSubmitButton';

export default {
  components: {
    AuthInput,
    AuthHeader,
    AuthSubmitButton,
  },
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
        .then(res => {
          let successMessage = this.$t('RESET_PASSWORD.API.SUCCESS_MESSAGE');
          if (res.data && res.data.message) {
            successMessage = res.data.message;
          }
          this.showAlert(successMessage);
        })
        .catch(error => {
          let errorMessage = this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
          if (error?.response?.data?.message) {
            errorMessage = error.response.data.message;
          }
          this.showAlert(errorMessage);
        });
    },
  },
};
</script>
<style lang="scss" scoped>
.reset--password {
  flex-direction: column;
  margin: var(--space-larger) 0;
}

.input-wrap {
  padding-bottom: var(--space-one);
}
</style>
