<template>
  <woot-modal :show.sync="show" :on-close="onCancel">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('EMAIL_TRANSCRIPT.TITLE')"
        :header-content="$t('EMAIL_TRANSCRIPT.DESC')"
      />
      <form @submit.prevent="onSubmit">
        <div class="medium-12 columns">
          <div v-if="currentChat.meta.sender && currentChat.meta.sender.email">
            <input
              id="contact"
              v-model="selectedType"
              type="radio"
              name="selectedType"
              value="contact"
            />
            <label for="contact">{{
              $t('EMAIL_TRANSCRIPT.FORM.SEND_TO_CONTACT')
            }}</label>
          </div>
          <div v-if="currentChat.meta.assignee">
            <input
              id="assignee"
              v-model="selectedType"
              type="radio"
              name="selectedType"
              value="assignee"
            />
            <label for="assignee">{{
              $t('EMAIL_TRANSCRIPT.FORM.SEND_TO_AGENT')
            }}</label>
          </div>
          <div>
            <input
              id="other_email_address"
              v-model="selectedType"
              type="radio"
              name="selectedType"
              value="other_email_address"
            />
            <label for="other_email_address">{{
              $t('EMAIL_TRANSCRIPT.FORM.SEND_TO_OTHER_EMAIL_ADDRESS')
            }}</label>
          </div>
          <div v-if="sentToOtherEmailAddress" class="medium-6 columns">
            <label :class="{ error: $v.email.$error }">
              <input
                v-model.trim="email"
                type="text"
                :placeholder="$t('EMAIL_TRANSCRIPT.FORM.EMAIL.PLACEHOLDER')"
                @input="$v.email.$touch"
              />
              <span v-if="$v.email.$error" class="message">
                {{ $t('EMAIL_TRANSCRIPT.FORM.EMAIL.ERROR') }}
              </span>
            </label>
          </div>
        </div>
        <div class="modal-footer">
          <div class="medium-12 row">
            <woot-submit-button
              :button-text="$t('EMAIL_TRANSCRIPT.SUBMIT')"
              :disabled="!isFormValid"
            />
            <button class="button clear" @click.prevent="onCancel">
              {{ $t('EMAIL_TRANSCRIPT.CANCEL') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </woot-modal>
</template>

<script>
import { required, minLength, email } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  mixins: [alertMixin],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    currentChat: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      email: '',
      selectedType: '',
      isSubmitting: false,
    };
  },
  validations: {
    email: {
      required,
      email,
      minLength: minLength(4),
    },
  },
  computed: {
    sentToOtherEmailAddress() {
      return this.selectedType === 'other_email_address';
    },
    isFormValid() {
      if (this.selectedType) {
        if (this.sentToOtherEmailAddress) {
          return !!this.email && !this.$v.email.$error;
        }
        return true;
      }
      return false;
    },
    selectedEmailAddress() {
      const { meta } = this.currentChat;
      switch (this.selectedType) {
        case 'contact':
          return meta.sender.email;
        case 'assignee':
          return meta.assignee.email;
        case 'other_email_address':
          return this.email;
        default:
          return '';
      }
    },
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    async onSubmit() {
      this.isSubmitting = false;
      try {
        await this.$store.dispatch('sendEmailTranscript', {
          email: this.selectedEmailAddress,
          conversationId: this.currentChat.id,
        });
        this.showAlert(this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_SUCCESS'));
        this.onCancel();
      } catch (error) {
        this.showAlert(this.$t('EMAIL_TRANSCRIPT.SEND_EMAIL_ERROR'));
      } finally {
        this.isSubmitting = false;
      }
    },
  },
};
</script>
