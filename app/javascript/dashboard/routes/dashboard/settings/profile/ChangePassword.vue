<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
// import FormButton from 'v3/components/Form/Button.vue';

export default {
  // components: {
  //   FormButton,
  // },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      currentPassword: '',
      password: '',
      passwordConfirmation: '',
      isPasswordChanging: false,
      errorMessage: '',
      inputStyles: {
        borderRadius: '12px',
        padding: '6px 12px',
        fontSize: '14px',
        marginBottom: '2px',
      },
    };
  },
  validations: {
    currentPassword: {
      required,
    },
    password: {
      minLength: minLength(6),
    },
    passwordConfirmation: {
      minLength: minLength(6),
      isEqPassword(value) {
        if (value !== this.password) {
          return false;
        }
        return true;
      },
    },
  },
  computed: {
    isButtonDisabled() {
      return (
        !this.currentPassword ||
        !this.passwordConfirmation ||
        !this.v$.passwordConfirmation.isEqPassword
      );
    },
  },
  methods: {
    async changePassword() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
        return;
      }
      let alertMessage = this.$t('PROFILE_SETTINGS.PASSWORD_UPDATE_SUCCESS');
      try {
        await this.$store.dispatch('updateProfile', {
          password: this.password,
          password_confirmation: this.passwordConfirmation,
          current_password: this.currentPassword,
        });
      } catch (error) {
        alertMessage =
          parseAPIErrorResponse(error) ||
          this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
      } finally {
        useAlert(alertMessage);
      }
    },
    redirectToHref() {
      const keycloakUrl = window.chatwootConfig.keycloakUrl;
      const keycloakRealm = window.chatwootConfig.keycloakRealm;
      const hrefURL = `${keycloakUrl}/realms/${keycloakRealm}/account/#/security/signingin`;
      window.open(hrefURL, '_blank');
    },
  },
};
</script>

<template>
  <form @submit.prevent="changePassword()">
    <div class="flex flex-col w-full gap-4">
      <div class="w-1/4">
        <h4 class="text-lg text-black-900 dark:text-slate-200">
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.TITLE') }}
        </h4>
        <p>{{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.NOTE') }}</p>
      </div>
      <div class="w-[45%]">
        <woot-button @click="redirectToHref">
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.BTN_TEXT') }}
        </woot-button>
      </div>
    </div>
  </form>
</template>
