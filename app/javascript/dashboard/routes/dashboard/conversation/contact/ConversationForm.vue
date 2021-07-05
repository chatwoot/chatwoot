<template>
  <form class="conversation--form" @submit.prevent="handleSubmit">
    <div v-if="showNoInboxAlert" class="callout warning">
      <p>
        {{ $t('NEW_CONVERSATION.NO_INBOX') }}
      </p>
    </div>
    <div v-else>
      <div class="row">
        <div class="columns">
          <label :class="{ error: $v.targetInbox.$error }">
            {{ $t('NEW_CONVERSATION.FORM.INBOX.LABEL') }}
            <select v-model="targetInbox">
              <option
                v-for="contactableInbox in inboxes"
                :key="contactableInbox.inbox.id"
                :value="contactableInbox"
              >
                {{ contactableInbox.inbox.name }}
              </option>
            </select>
            <span v-if="$v.targetInbox.$error" class="message">
              {{ $t('NEW_CONVERSATION.FORM.INBOX.ERROR') }}
            </span>
          </label>
        </div>
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
      </div>
      <div class="row">
        <div class="columns">
          <label :class="{ error: $v.message.$error }">
            {{ $t('NEW_CONVERSATION.FORM.MESSAGE.LABEL') }}
            <textarea
              v-model="message"
              class="message-input"
              type="text"
              :placeholder="$t('NEW_CONVERSATION.FORM.MESSAGE.PLACEHOLDER')"
              @input="$v.message.$touch"
            />
            <span v-if="$v.message.$error" class="message">
              {{ $t('NEW_CONVERSATION.FORM.MESSAGE.ERROR') }}
            </span>
          </label>
        </div>
      </div>
    </div>
    <div class="modal-footer">
      <button class="button clear" @click.prevent="onCancel">
        {{ $t('NEW_CONVERSATION.FORM.CANCEL') }}
      </button>
      <woot-button type="submit" :is-loading="conversationsUiFlags.isCreating">
        {{ $t('NEW_CONVERSATION.FORM.SUBMIT') }}
      </woot-button>
    </div>
  </form>
</template>

<script>
import { mapGetters } from 'vuex';
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
    onSubmit: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      name: '',
      message: '',
      selectedInbox: '',
    };
  },
  validations: {
    message: {
      required,
    },
    targetInbox: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
      conversationsUiFlags: 'contactConversations/getUIFlags',
    }),
    getNewConversation() {
      return {
        inboxId: this.targetInbox.inbox.id,
        sourceId: this.targetInbox.source_id,
        contactId: this.contact.id,
        message: { content: this.message },
      };
    },
    targetInbox: {
      get() {
        return this.selectedInbox || '';
      },
      set(value) {
        this.selectedInbox = value;
      },
    },
    showNoInboxAlert() {
      if (!this.contact.contactableInboxes) {
        return false;
      }
      return this.inboxes.length === 0 && !this.uiFlags.isFetchingInboxes;
    },
    inboxes() {
      return this.contact.contactableInboxes || [];
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
        this.showAlert(this.$t('NEW_CONVERSATION.FORM.SUCCESS_MESSAGE'));
      } catch (error) {
        if (error instanceof ExceptionWithMessage) {
          this.showAlert(error.data);
        } else {
          this.showAlert(this.$t('NEW_CONVERSATION.FORM.ERROR_MESSAGE'));
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

.message-input {
  min-height: 8rem;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
}
</style>
