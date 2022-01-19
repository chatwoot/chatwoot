<template>
  <form @submit.prevent="changePassword()">
    <div class="profile--settings--row row">
      <div class="columns small-3">
        <h4 class="block-title">
          {{ $t('PROFILE_SETTINGS.FORM.EMAIL_SIGNATURE_SECTION.TITLE') }}
        </h4>
        <p>{{ $t('PROFILE_SETTINGS.FORM.EMAIL_SIGNATURE_SECTION.NOTE') }}</p>
      </div>
      <div class="columns small-9 medium-5">
        <div>
          <label for="email-signature-input">{{
            $t('PROFILE_SETTINGS.FORM.EMAIL_SIGNATURE.LABEL')
          }}</label>
          <resizable-text-area
            id="email-signature-input"
            v-model="emailSignature"
            rows="4"
            type="text"
            :placeholder="
              $t('PROFILE_SETTINGS.FORM.EMAIL_SIGNATURE.PLACEHOLDER')
            "
            @input="handleInput"
          />
        </div>

        <div>
          <input
            id="enable-email-signature"
            v-model="enableEmailSignature"
            class="notification--checkbox"
            type="checkbox"
            value="email_conversation_creation"
            @input="handleEmailInput"
          />
          <label for="enable-email-signature">
            {{ $t('PROFILE_SETTINGS.FORM.ENABLE_EMAIL_SIGNATURE.LABEL') }}
          </label>
        </div>

        <woot-button
          :is-loading="isPasswordChanging"
          type="submit"
          :disabled="!currentPassword"
        >
          {{ $t('PROFILE_SETTINGS.FORM.EMAIL_SIGNATURE_SECTION.BTN_TEXT') }}
        </woot-button>
      </div>
    </div>
  </form>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';

import ResizableTextArea from 'shared/components/ResizableTextArea';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    ResizableTextArea,
  },
  mixins: [alertMixin],
  data() {
    return {
      emailSignature: '',
      password: '',
      enableEmailSignature: false,
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
          current_password: this.currentPassword,
        });
        this.errorMessage = this.$t('PROFILE_SETTINGS.PASSWORD_UPDATE_SUCCESS');
      } catch (error) {
        this.errorMessage = this.$t('RESET_PASSWORD.API.ERROR_MESSAGE');
        if (error?.response?.data?.message) {
          this.errorMessage = error.response.data.message;
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
