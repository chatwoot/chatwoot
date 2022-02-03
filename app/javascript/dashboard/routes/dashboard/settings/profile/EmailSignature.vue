<template>
  <form @submit.prevent="updateSignature()">
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
            v-model="messageSignature"
            rows="4"
            type="text"
            :placeholder="
              $t('PROFILE_SETTINGS.FORM.EMAIL_SIGNATURE.PLACEHOLDER')
            "
            @blur="$v.messageSignature.$touch"
          />
        </div>

        <div>
          <input
            id="enable-email-signature"
            v-model="enableMessageSignature"
            class="notification--checkbox"
            type="checkbox"
            value="email_conversation_creation"
          />
          <label for="enable-email-signature">
            {{ $t('PROFILE_SETTINGS.FORM.ENABLE_EMAIL_SIGNATURE.LABEL') }}
          </label>
        </div>
        <woot-button
          :is-loading="isUpdating"
          type="submit"
          :is-disabled="$v.messageSignature.$invalid"
        >
          {{ $t('PROFILE_SETTINGS.FORM.EMAIL_SIGNATURE_SECTION.BTN_TEXT') }}
        </woot-button>
      </div>
    </div>
  </form>
</template>

<script>
import { required } from 'vuelidate/lib/validators';
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
      messageSignature: '',
      enableMessageSignature: false,
      isUpdating: false,
      errorMessage: '',
    };
  },
  validations: {
    messageSignature: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentUserId: 'getCurrentUserID',
    }),
  },
  watch: {
    currentUser() {
      this.initValues();
    },
  },
  mounted() {
    this.initValues();
  },
  methods: {
    initValues() {
      const {
        message_signature: messageSignature,
        message_signature_enabled: enableMessageSignature,
      } = this.currentUser;
      this.messageSignature = messageSignature;
      this.enableMessageSignature = enableMessageSignature;
    },
    async updateSignature() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        this.showAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
        return;
      }

      try {
        await this.$store.dispatch('updateProfile', {
          message_signature: this.messageSignature,
          message_signature_enabled: this.enableMessageSignature,
        });
        this.errorMessage = this.$t(
          'PPROFILE_SETTINGS.FORM.EMAIL_SIGNATURE_SECTION.API_SUCCESS'
        );
      } catch (error) {
        this.errorMessage = this.$t(
          'PROFILE_SETTINGS.FORM.EMAIL_SIGNATURE_SECTION.API_ERROR'
        );
        if (error?.response?.data?.message) {
          this.errorMessage = error.response.data.message;
        }
      } finally {
        this.isUpdating = false;
        this.showAlert(this.errorMessage);
      }
    },
  },
};
</script>

<style lang="scss">
.profile--settings--row {
  border: 1px solid var(--color-border);
  padding: var(--space-normal);

  .small-3 {
    padding: var(--space-normal) var(--space-medium) var(--space-normal) 0;
  }
  .small-9 {
    padding: var(--space-normal);
  }
}
</style>
