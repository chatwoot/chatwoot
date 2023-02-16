<template>
  <form @submit.prevent="updateSignature()">
    <div class="profile--settings--row row">
      <div class="columns small-3">
        <h4 class="block-title">
          {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.TITLE') }}
        </h4>
        <p>{{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.NOTE') }}</p>
      </div>
      <div class="columns small-9 medium-5">
        <div>
          <label for="message-signature-input">{{
            $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.LABEL')
          }}</label>
          <woot-message-editor
            id="message-signature-input"
            v-model="messageSignature"
            class="message-editor"
            :is-format-mode="true"
            :placeholder="
              $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.PLACEHOLDER')
            "
            @blur="$v.messageSignature.$touch"
          />
        </div>
        <woot-button
          :is-loading="isUpdating"
          type="submit"
          :is-disabled="$v.messageSignature.$invalid"
        >
          {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.BTN_TEXT') }}
        </woot-button>
      </div>
    </div>
  </form>
</template>

<script>
import { required } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';

import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    WootMessageEditor,
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
      const { message_signature: messageSignature } = this.currentUser;
      this.messageSignature = messageSignature || '';
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
        });
        this.errorMessage = this.$t(
          'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.API_SUCCESS'
        );
      } catch (error) {
        this.errorMessage = this.$t(
          'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.API_ERROR'
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
  .ProseMirror-woot-style {
    height: 8rem;
  }

  .editor-root {
    background: var(--white);
    margin-bottom: var(--space-normal);
  }
}
</style>
