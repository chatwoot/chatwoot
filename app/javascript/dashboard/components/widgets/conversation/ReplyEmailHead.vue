<template>
  <div>
    <div class="input-group-wrap">
      <div class="input-group small" :class="{ error: $v.ccEmailsVal.$error }">
        <label class="input-group-label">
          {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.LABEL') }}
        </label>
        <div class="input-group-field">
          <woot-input
            v-model.trim="$v.ccEmailsVal.$model"
            type="email"
            :class="{ error: $v.ccEmailsVal.$error }"
            :placeholder="$t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.PLACEHOLDER')"
            @blur="onBlur"
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
      <span v-if="$v.ccEmailsVal.$error" class="message">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.CC.ERROR') }}
      </span>
    </div>
    <div v-if="showBcc" class="input-group-wrap">
      <div class="input-group small" :class="{ error: $v.bccEmailsVal.$error }">
        <label class="input-group-label">
          {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.LABEL') }}
        </label>
        <div class="input-group-field">
          <woot-input
            v-model.trim="$v.bccEmailsVal.$model"
            type="email"
            :class="{ error: $v.bccEmailsVal.$error }"
            :placeholder="
              $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.PLACEHOLDER')
            "
            @blur="onBlur"
          />
        </div>
      </div>
      <span v-if="$v.bccEmailsVal.$error" class="message">
        {{ $t('CONVERSATION.REPLYBOX.EMAIL_HEAD.BCC.ERROR') }}
      </span>
    </div>
  </div>
</template>

<script>
import { validEmailsByComma } from './helpers/emailHeadHelper';
export default {
  props: {
    clearMails: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showBcc: false,
      ccEmailsVal: '',
      bccEmailsVal: '',
    };
  },
  validations: {
    ccEmailsVal: {
      hasValidEmails(value) {
        return validEmailsByComma(value);
      },
    },
    bccEmailsVal: {
      hasValidEmails(value) {
        return validEmailsByComma(value);
      },
    },
  },
  methods: {
    handleAddBcc() {
      this.showBcc = true;
    },
    onBlur() {
      this.$v.$touch();
      this.$emit("set-emails", { bccEmails: this.bccEmailsVal, ccEmails: this.ccEmailsVal });
    },
  },
  watch: {
    clearMails: function(value){
      if(value) {
        this.ccEmailsVal = '';
        this.bccEmailsVal = '';
        this.clearMails = false;
      }
    }
  }
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
