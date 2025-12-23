<template>
  <woot-modal :show="show" :on-close="onClose">
    <div class="h-auto overflow-auto flex flex-col">
      <woot-modal-header
        :header-title="$t('FORWARD_EMAIL_MODAL.TITLE')"
        :header-content="$t('FORWARD_EMAIL_MODAL.DESC')"
      />
      <form class="w-full" @submit.prevent="onSubmit">
        <div class="w-full flex flex-col gap-4">
          <div class="w-full">
            <label :class="{ error: emailError }">
              {{ $t('FORWARD_EMAIL_MODAL.TO_LABEL') }}
              <input
                v-model="toEmails"
                type="text"
                :placeholder="$t('FORWARD_EMAIL_MODAL.TO_PLACEHOLDER')"
                @blur="validateEmails"
              />
              <span v-if="emailError" class="message">
                {{ emailError }}
              </span>
            </label>
          </div>
          <div class="w-full">
            <label>
              {{ $t('FORWARD_EMAIL_MODAL.COMMENT_LABEL') }}
              <textarea
                v-model="comment"
                rows="4"
                :placeholder="$t('FORWARD_EMAIL_MODAL.COMMENT_PLACEHOLDER')"
              />
            </label>
          </div>
        </div>
        <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
          <woot-submit-button
            :disabled="!isValid"
            :loading="isForwarding"
            :button-text="$t('FORWARD_EMAIL_MODAL.SUBMIT')"
          />
          <button class="button clear" @click.prevent="onClose">
            {{ $t('FORWARD_EMAIL_MODAL.CANCEL') }}
          </button>
        </div>
      </form>
    </div>
  </woot-modal>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import { mapGetters } from 'vuex';

export default {
  mixins: [alertMixin],
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    messageId: {
      type: Number,
      required: true,
    },
    conversationId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      toEmails: '',
      comment: '',
      emailError: '',
      isForwarding: false,
    };
  },
  computed: {
    ...mapGetters({
      currentAccountId: 'getCurrentAccountId',
    }),
    isValid() {
      return this.toEmails.trim() !== '' && !this.emailError;
    },
  },
  methods: {
    validateEmails() {
      const emails = this.toEmails
        .split(',')
        .map(e => e.trim())
        .filter(e => e);
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

      const invalidEmails = emails.filter(email => !emailRegex.test(email));

      if (invalidEmails.length > 0) {
        this.emailError = this.$t('FORWARD_EMAIL_MODAL.INVALID_EMAIL', {
          email: invalidEmails[0],
        });
      } else if (emails.length === 0) {
        this.emailError = this.$t('FORWARD_EMAIL_MODAL.REQUIRED');
      } else {
        this.emailError = '';
      }
    },
    async onSubmit() {
      this.validateEmails();
      if (!this.isValid) return;

      this.isForwarding = true;
      try {
        await this.$store.dispatch('forwardMessage', {
          conversationId: this.conversationId,
          messageId: this.messageId,
          toEmails: this.toEmails,
          comment: this.comment,
        });
        this.showAlert(
          this.$t('CONVERSATION.CONTEXT_MENU.FORWARD_EMAIL_SUCCESS')
        );
        this.onClose();
      } catch (error) {
        this.showAlert(
          error.response?.data?.error ||
            this.$t('CONVERSATION.CONTEXT_MENU.FORWARD_EMAIL_ERROR')
        );
      } finally {
        this.isForwarding = false;
      }
    },
    onClose() {
      this.toEmails = '';
      this.comment = '';
      this.emailError = '';
      this.$emit('close');
    },
  },
};
</script>

<style lang="scss" scoped>
label {
  &.error {
    input,
    textarea {
      border-color: var(--r-400);
    }
  }
}

.message {
  color: var(--r-400);
  font-size: var(--font-size-mini);
  margin-top: var(--space-smaller);
  display: block;
}
</style>
