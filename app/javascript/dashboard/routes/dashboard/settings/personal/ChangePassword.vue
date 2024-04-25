<template>
  <form @submit.prevent="changePassword()">
    <div class="flex flex-col w-full gap-4">
      <form-input
        v-model="currentPassword"
        type="password"
        name="currentPassword"
        :class="{ error: $v.currentPassword.$error }"
        :label="$t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.LABEL')"
        :placeholder="$t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.PLACEHOLDER')"
        :has-error="$v.currentPassword.$error"
        :error-message="
          $v.currentPassword.$error
            ? $t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.ERROR')
            : ''
        "
        @blur="$v.currentPassword.$touch"
      />
      <form-input
        v-model="password"
        type="password"
        name="password"
        :class="{ error: $v.password.$error }"
        :label="$t('PROFILE_SETTINGS.FORM.PASSWORD.LABEL')"
        :placeholder="$t('PROFILE_SETTINGS.FORM.PASSWORD.PLACEHOLDER')"
        :has-error="$v.password.$error"
        :error-message="
          $v.password.$error ? $t('PROFILE_SETTINGS.FORM.PASSWORD.ERROR') : ''
        "
        @blur="$v.password.$touch"
      />

      <form-input
        v-model="passwordConfirmation"
        type="password"
        name="passwordConfirmation"
        :class="{ error: $v.passwordConfirmation.$error }"
        :label="$t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.LABEL')"
        :placeholder="
          $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.PLACEHOLDER')
        "
        :has-error="$v.passwordConfirmation.$error"
        :error-message="
          $v.passwordConfirmation.$error
            ? $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.ERROR')
            : ''
        "
        @blur="$v.passwordConfirmation.$touch"
      />
      <form-button
        type="submit"
        color-scheme="primary"
        variant="solid"
        size="large"
        :disabled="
          !currentPassword ||
          !passwordConfirmation ||
          !$v.passwordConfirmation.isEqPassword
        "
      >
        {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.BTN_TEXT') }}
      </form-button>
    </div>
  </form>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import { parseAPIErrorResponse } from 'dashboard/store/utils/api';
import FormButton from 'v3/components/Form/Button.vue';
import FormInput from 'v3/components/Form/Input.vue';

export default {
  components: {
    FormButton,
    FormInput,
  },
  mixins: [alertMixin],
  data() {
    return {
      currentPassword: '',
      password: '',
      passwordConfirmation: '',
      isPasswordChanging: false,
      errorMessage: '',
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
  methods: {
    async changePassword() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.showAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
        return;
      }

      try {
        await this.$store.dispatch('updateProfile', {
          password: this.password,
          password_confirmation: this.passwordConfirmation,
          current_password: this.currentPassword,
        });
        this.errorMessage = this.$t('PROFILE_SETTINGS.PASSWORD_UPDATE_SUCCESS');
      } catch (error) {
        this.errorMessage =
          parseAPIErrorResponse(error) ||
          this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
      } finally {
        this.isPasswordChanging = false;
        this.showAlert(this.errorMessage);
      }
    },
  },
};
</script>
