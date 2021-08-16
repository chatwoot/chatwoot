<template>
  <div>
    <div class="input-group-wrap">
      <div class="input-group small" :class="{ error: $v.ccEmails.$error }">
        <label class="input-group-label">
          {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.LABEL') }}
        </label>
        <div class="input-group-field">
          <woot-input
            v-model.trim="ccEmails"
            type="email"
            :class="{ error: $v.ccEmails.$error }"
            :placeholder="$t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.PLACEHOLDER')"
            @blur="$v.ccEmails.$touch"
          />
        </div>
        <woot-button
          v-if="!showBcc"
          variant="clear"
          size="small"
          @click="handleAddBcc"
        >
          {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.ADD_BCC') }}
        </woot-button>
      </div>
      <span v-if="$v.ccEmails.$error" class="message">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.ERROR') }}
      </span>
    </div>
    <div v-if="showBcc" class="input-group-wrap">
      <div class="input-group small" :class="{ error: $v.bccEmails.$error }">
        <label class="input-group-label">
          {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.LABEL') }}
        </label>
        <div class="input-group-field">
          <woot-input
            v-model.trim="bccEmails"
            type="email"
            :class="{ error: $v.bccEmails.$error }"
            :placeholder="
              $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.PLACEHOLDER')
            "
            @blur="$v.bccEmails.$touch"
          />
        </div>
      </div>
      <span v-if="$v.bccEmails.$error" class="message">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.ERROR') }}
      </span>
    </div>
  </div>
</template>

<script>
import { validEmailsByComma } from './helpers/emailHeadHelper';
export default {
  props: {
    ccEmails: {
      type: String,
      default: '',
    },
    bccEmails: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      showBcc: false,
    };
  },
  validations: {
    ccEmails: {
      hasValidEmails(value) {
        return validEmailsByComma(value);
      },
    },
    bccEmails: {
      hasValidEmails(value) {
        return validEmailsByComma(value);
      },
    },
  },
  methods: {
    handleAddBcc() {
      this.showBcc = true;
    },
  },
};
</script>
<style lang="scss" scoped>
.input-group-wrap .message {
  font-size: var(--font-size-small);
  color: var(--r-500);
}
.input-group {
  border-bottom: 1px solid var(--color-border);
  margin-bottom: var(--space-smaller);
  margin-top: var(--space-smaller);

  .input-group-label {
    border-color: transparent;
    background: transparent;
    font-size: var(--font-size-mini);
    font-weight: var(--font-weight-bold);
  }
  .input-group-field::v-deep input {
    margin-bottom: 0;
    border-color: transparent;
  }
}

.input-group.error {
  border-bottom-color: var(--r-500);
  .input-group-label {
    color: var(--r-500);
  }
}
</style>
