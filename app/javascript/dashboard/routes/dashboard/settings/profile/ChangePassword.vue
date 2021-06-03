<template>
  <form @submit.prevent="changePassword()">
    <div class="profile--settings--row row">
      <div class="columns small-3">
        <h4 class="block-title">
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.TITLE') }}
        </h4>
        <p>{{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.NOTE') }}</p>
      </div>
      <div class="columns small-9 medium-5">
        <woot-input
          v-model="currentPassword"
          type="password"
          :class="{ error: $v.currentPassword.$error }"
          :label="$t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.LABEL')"
          :placeholder="
            $t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.PLACEHOLDER')
          "
          :error="
            $v.currentPassword.$error
              ? $t('PROFILE_SETTINGS.FORM.CURRENT_PASSWORD.ERROR')
              : ''
          "
          @blur="$v.currentPassword.$touch"
        />

        <woot-input
          v-model="password"
          type="password"
          :class="{ error: $v.password.$error }"
          :label="$t('PROFILE_SETTINGS.FORM.PASSWORD.LABEL')"
          :placeholder="$t('PROFILE_SETTINGS.FORM.PASSWORD.PLACEHOLDER')"
          :error="
            $v.password.$error ? $t('PROFILE_SETTINGS.FORM.PASSWORD.ERROR') : ''
          "
          @blur="$v.password.$touch"
        />

        <woot-input
          v-model="passwordConfirmation"
          type="password"
          :class="{ error: $v.passwordConfirmation.$error }"
          :label="$t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.LABEL')"
          :placeholder="
            $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.PLACEHOLDER')
          "
          :error="
            $v.passwordConfirmation.$error
              ? $t('PROFILE_SETTINGS.FORM.PASSWORD_CONFIRMATION.ERROR')
              : ''
          "
          @blur="$v.passwordConfirmation.$touch"
        />

        <woot-button
          :is-loading="isPasswordChanging"
          type="submit"
          :disabled="
            !currentPassword ||
              !passwordConfirmation ||
              !$v.passwordConfirmation.isEqPassword
          "
        >
          {{ $t('PROFILE_SETTINGS.FORM.PASSWORD_SECTION.BTN_TEXT') }}
        </woot-button>
      </div>
    </div>
  </form>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';

export default {
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
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentUserId: 'getCurrentUserID',
    }),
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
        this.errorMessage = this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
        if (error?.response?.data?.error) {
          this.errorMessage = error.response.data.error;
        }
      } finally {
        this.isPasswordChanging = false;
        this.showAlert(this.errorMessage);
      }
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/mixins.scss';

.profile--settings--row {
  @include border-normal-bottom;
  padding: var(--space-normal);
  .small-3 {
    padding: var(--space-normal) var(--space-medium) var(--space-normal) 0;
  }
  .small-9 {
    padding: var(--space-normal);
  }
}
</style>
