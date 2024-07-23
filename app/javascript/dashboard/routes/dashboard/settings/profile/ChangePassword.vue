<template>
  <form @submit.prevent="changePassword()">
    <div class="flex flex-col w-full gap-4">
      <woot-input
        v-model="currentPassword"
        type="password"
        :styles="inputStyles"
        :class="{ error: $v.currentPassword.$error }"
        :label="$t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.LABEL')"
        :placeholder="$t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.PLACEHOLDER')"
        :error="`${
          $v.currentPassword.$error
            ? $t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.ERROR')
            : ''
        }`"
        @input="$v.currentPassword.$touch"
      />

      <woot-input
        v-model="password"
        type="password"
        :styles="inputStyles"
        :class="{ error: $v.password.$error }"
        :label="$t('PROFILE_SETTINGS.FORM.PASSWORD.LABEL')"
        :placeholder="$t('PROFILE_SETTINGS.FORM.PASSWORD.PLACEHOLDER')"
        :error="`${
          $v.password.$error ? $t('PROFILE_SETTINGS.FORM.PASSWORD.ERROR') : ''
        }`"
        @input="$v.password.$touch"
      />

      <woot-input
        v-model="passwordConfirmation"
        type="password"
        :styles="inputStyles"
        :class="{ error: $v.passwordConfirmation.$error }"
        :label="$t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.LABEL')"
        :placeholder="
          $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.PLACEHOLDER')
        "
        :error="`${
          $v.passwordConfirmation.$error
            ? $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.ERROR')
            : ''
        }`"
        @input="$v.passwordConfirmation.$touch"
      />

      <form-button
        type="submit"
        color-scheme="primary"
        variant="solid"
        size="large"
        :disabled="isButtonDisabled"
      >
        {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.BTN_TEXT') }}
      </form-button>
    </div>
  </form>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import { useAlert } from 'dashboard/composables';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import FormButton from 'v3/components/Form/Button.vue';
export default {
  components: {
    FormButton,
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
        !this.$v.passwordConfirmation.isEqPassword
      );
    },
  },
  methods: {
    async changePassword() {
      this.$v.$touch();
      if (this.$v.$invalid) {
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
  },
};
</script>
