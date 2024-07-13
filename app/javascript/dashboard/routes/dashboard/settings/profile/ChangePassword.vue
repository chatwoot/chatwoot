<template>
  <form @submit.prevent="changePassword()">
    <div
      class="profile--settings--row text-black-900 dark:text-slate-300 flex items-center"
    >
      <div class="w-1/4">
        <h4 class="text-lg text-black-900 dark:text-slate-200">
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.TITLE') }}
        </h4>
        <p>{{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.NOTE') }}</p>
      </div>
      <div class="w-[45%] p-4">
        <woot-button @click="redirectToHref">
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.BTN_TEXT') }}
        </woot-button>
      </div>
    </div>
  </form>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import FormButton from 'v3/components/Form/Button.vue';
export default {
  components: {
    FormButton,
  },
  mixins: [alertMixin],
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
        !this.$v.passwordConfirmation.isEqPassword
      );
    },
  },
  methods: {
    async changePassword() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.showAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
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
        this.showAlert(alertMessage);
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
