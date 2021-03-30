<template>
  <form class="conversation--form" @submit.prevent="handleSubmit">
    <div class="row">
      <div class="columns">
        <label>
          {{ $t('NEW_CONVERSATION.FORM.TO.LABEL') }}
          <div class="contact-input">
            <thumbnail
              :src="contact.thumbnail"
              size="24px"
              :username="contact.name"
              :status="contact.availability_status"
            />
            <h4 class="text-block-title contact-name">
              {{ contact.name }}
            </h4>
          </div>
        </label>
      </div>
      <div class="columns">
        <label :class="{ error: $v.selectedInbox.$error }">
          {{ $t('NEW_CONVERSATION.FORM.INBOX.LABEL') }}
          <select v-model="selectedInbox">
            <option
              v-for="contactInbox in inboxes"
              :key="contactInbox.source_id"
              :value="contactInbox"
            >
              {{ contactInbox.inbox.name }}
            </option>
          </select>
        </label>
      </div>
    </div>
    <div class="row">
      <div class="columns">
        <label :class="{ error: $v.message.$error }">
          {{ $t('NEW_CONVERSATION.FORM.MESSAGE.LABEL') }}
          <textarea
            v-model="message"
            type="text"
            :placeholder="$t('NEW_CONVERSATION.FORM.MESSAGE.PLACEHOLDER')"
            @input="$v.message.$touch"
          />
        </label>
      </div>
    </div>
    <div class="modal-footer">
      <button class="button clear" @click.prevent="onCancel">
        {{ $t('NEW_CONVERSATION.FORM.CANCEL') }}
      </button>
      <woot-submit-button
        :loading="inProgress"
        :button-text="$t('NEW_CONVERSATION.FORM.SUBMIT')"
      />
    </div>
  </form>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail';

import alertMixin from 'shared/mixins/alertMixin';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import { required } from 'vuelidate/lib/validators';

export default {
  components: {
    Thumbnail,
  },
  mixins: [alertMixin],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    inboxes: {
      type: Object,
      default: () => [],
    },
    inProgress: {
      type: Boolean,
      default: false,
    },
    onSubmit: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      name: '',
      phoneNumber: '',
      message: '',
      selectedInbox: '',
    };
  },
  validations: {
    message: {
      required,
    },
    selectedInbox: {
      required,
    },
  },
  computed: {
    getNewConversation() {
      const { inbox, source_id: sourceId } = this.selectedInbox;
      return {
        sourceId,
        selectedInbox: inbox.id,
        contactId: this.contact.id,
        message: this.message,
      };
    },
  },
  methods: {
    onCancel() {
      this.$emit('cancel');
    },
    onSuccess() {
      this.$emit('success');
    },

    async handleSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        const payload = this.getNewConversation;

        await this.onSubmit(payload);
        this.onSuccess();
        this.showAlert(this.$t('NEW_CONVERSATION.SUCCESS_MESSAGE'));
      } catch (error) {
        if (error instanceof ExceptionWithMessage) {
          this.showAlert(error.data);
        } else {
          this.showAlert(this.$t('NEW_CONVERSATION.ERROR_MESSAGE'));
        }
      }
    },
  },
};
</script>

<style scoped lang="scss">
.conversation--form {
  padding: var(--space-normal) var(--space-large) var(--space-large);

  .columns {
    padding: 0 var(--space-smaller);
  }
}

.input-group-label {
  font-size: var(--font-size-small);
}

.contact-input {
  display: flex;
  align-items: center;
  height: 3.9rem;
  background: var(--color-background-light);

  border: 1px solid var(--color-border);
  padding: var(--space-smaller) var(--space-small);
  border-radius: var(--border-radius-small);

  .contact-name {
    margin: 0;
    margin-left: var(--space-small);
  }
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
}
</style>
