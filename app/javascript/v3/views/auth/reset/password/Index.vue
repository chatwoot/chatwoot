<script>
import { useVuelidate } from '@vuelidate/core';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { required, minLength, email } from '@vuelidate/validators';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';
import FormInput from '../../../../components/Form/Input.vue';
import { resetPassword } from '../../../../api/auth';
import SubmitButton from '../../../../components/Button/SubmitButton.vue';

export default {
  components: { FormInput, SubmitButton },
  mixins: [globalConfigMixin],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      credentials: { email: '' },
      resetPassword: {
        message: '',
        showLoading: false,
      },
      error: '',
    };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
  },
  validations() {
    return {
      credentials: {
        email: {
          required,
          email,
          minLength: minLength(4),
        },
      },
    };
  },
  methods: {
    showAlertMessage(message) {
      // Reset loading, current selected agent
      this.resetPassword.showLoading = false;
      useAlert(message);
    },
    submit() {
      this.resetPassword.showLoading = true;
      resetPassword(this.credentials)
        .then(res => {
          let successMessage = this.$t('RESET_PASSWORD.API.SUCCESS_MESSAGE');
          if (res.data && res.data.message) {
            successMessage = res.data.message;
          }
          this.showAlertMessage(successMessage);
        })
        .catch(error => {
          let errorMessage = this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
          if (error?.response?.data?.message) {
            errorMessage = error.response.data.message;
          }
          this.showAlertMessage(errorMessage);
        });
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col justify-center w-full min-h-screen py-12 bg-woot-25 sm:px-6 lg:px-8 dark:bg-slate-900"
  >
    <form
      class="bg-white shadow sm:mx-auto sm:w-full sm:max-w-lg dark:bg-slate-800 p-11 sm:shadow-lg sm:rounded-lg"
      @submit.prevent="submit"
    >
      <h1
        class="mb-1 text-2xl font-medium tracking-tight text-left text-slate-900 dark:text-white"
      >
        {{ $t('RESET_PASSWORD.TITLE') }}
      </h1>
      <p
        class="mb-4 text-sm font-normal leading-6 tracking-normal text-slate-600 dark:text-woot-50"
      >
        {{
          useInstallationName(
            $t('RESET_PASSWORD.DESCRIPTION'),
            globalConfig.installationName
          )
        }}
      </p>
      <div class="space-y-5">
        <FormInput
          v-model="credentials.email"
          name="email_address"
          :has-error="v$.credentials.email.$error"
          :error-message="$t('RESET_PASSWORD.EMAIL.ERROR')"
          :placeholder="$t('RESET_PASSWORD.EMAIL.PLACEHOLDER')"
          @input="v$.credentials.email.$touch"
        />
        <SubmitButton
          :disabled="v$.credentials.email.$invalid || resetPassword.showLoading"
          :button-text="$t('RESET_PASSWORD.SUBMIT')"
          :loading="resetPassword.showLoading"
        />
      </div>
      <p class="mt-4 -mb-1 text-sm text-slate-600 dark:text-woot-50">
        {{ $t('RESET_PASSWORD.GO_BACK_TO_LOGIN') }}
        <router-link to="/auth/login" class="text-link">
          {{ $t('COMMON.CLICK_HERE') }}.
        </router-link>
      </p>
    </form>
  </div>
</template>
