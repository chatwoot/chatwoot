<script>
import { mapGetters } from 'vuex';
import MentionBox from '../mentions/MentionBox.vue';
import Modal from 'dashboard/components/Modal.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { MESSAGE_MAX_LENGTH } from 'shared/helpers/MessageTypeHelper';
import { CHAR_LENGTH_WARNING } from 'dashboard/components/widgets/WootWriter/constants.js';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  getMessageVariables,
  getUndefinedVariablesInMessage,
  replaceVariablesInMessage,
} from '@chatwoot/utils';

export default {
  components: { MentionBox, Modal, NextButton },
  props: {
    searchKey: {
      type: String,
      default: '',
    },
    channelType: {
      type: String,
      default: '',
    },
    inboxId: {
      type: Number,
      default: null,
    },
  },
  emits: ['replace', 'cannedSelected'],
  data() {
    return {
      selectedCannedResponse: null,
      undefinedVariables: [],
      showVariablePopup: false,
      userDefinedVariables: {},
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      cannedMessages: 'getCannedResponses',
    }),
    currentContact() {
      const senderId = this.currentChat?.meta?.sender?.id;
      if (!senderId) return null;
      return this.$store.getters['contacts/getContact'](senderId);
    },
    items() {
      return this.cannedMessages.map(cannedMessage => ({
        label: cannedMessage.short_code,
        key: cannedMessage.short_code,
        description: cannedMessage.content,
        id: cannedMessage.id,
      }));
    },
    isFormValid() {
      return this.undefinedVariables.every(variable => {
        return this.userDefinedVariables[variable] !== '';
      });
    },
    livePreviewMessage() {
      if (!this.selectedCannedResponse) return '';
      const rawMessage = this.selectedCannedResponse.description;

      const contextVars =
        this.currentChat && this.currentContact
          ? getMessageVariables({
              conversation: this.currentChat,
              contact: this.currentContact,
            })
          : {};

      return this.formatVariablePreview(
        rawMessage,
        contextVars,
        this.userDefinedVariables
      );
    },
    livePreviewMessageLength() {
      const parser = new DOMParser();
      const doc = parser.parseFromString(this.livePreviewMessage, 'text/html');
      return doc.body.textContent.length;
    },
    maxLength() {
      if (this.isPrivate) {
        return MESSAGE_MAX_LENGTH.GENERAL;
      }
      if (this.channelType === INBOX_TYPES.FB) {
        return MESSAGE_MAX_LENGTH.FACEBOOK;
      }
      if (this.channelType === INBOX_TYPES.WHATSAPP) {
        return MESSAGE_MAX_LENGTH.TWILIO_WHATSAPP;
      }
      if (this.channelType === INBOX_TYPES.SMS) {
        return MESSAGE_MAX_LENGTH.TWILIO_SMS;
      }
      if (this.channelType === INBOX_TYPES.EMAIL) {
        return MESSAGE_MAX_LENGTH.EMAIL;
      }
      return MESSAGE_MAX_LENGTH.GENERAL;
    },
    isMessageLengthReachingThreshold() {
      return this.livePreviewMessageLength > this.maxLength - 50;
    },
    charactersRemaining() {
      return this.maxLength - this.livePreviewMessageLength;
    },
    characterLengthWarning() {
      return this.charactersRemaining < 0
        ? `${-this.charactersRemaining} ${CHAR_LENGTH_WARNING.NEGATIVE}`
        : `${this.charactersRemaining} ${CHAR_LENGTH_WARNING.UNDER_50}`;
    },
    charLengthClass() {
      return this.charactersRemaining < 0 ? 'text-red-600' : 'text-slate-600';
    },
  },
  watch: {
    searchKey() {
      this.fetchCannedResponses();
    },
  },
  mounted() {
    this.fetchCannedResponses();
  },
  methods: {
    fetchCannedResponses() {
      const inboxId = this.currentChat.inbox_id || this.inboxId;
      this.$store.dispatch('getCannedResponse', {
        searchKey: this.searchKey,
        inboxId,
      });
    },
    handleMentionClick(item = {}) {
      let variables = {};
      const hasContextData = this.currentChat && this.currentContact;

      if (hasContextData) {
        variables = getMessageVariables({
          conversation: this.currentChat,
          contact: this.currentContact,
        });
      }
      const undefinedVariables = getUndefinedVariablesInMessage({
        message: item.description,
        variables,
      });
      if (undefinedVariables.length > 0) {
        this.selectedCannedResponse = item;
        this.undefinedVariables = undefinedVariables;
        this.userDefinedVariables = Object.fromEntries(
          undefinedVariables.map(variable => [variable, ''])
        );
        this.showVariablePopup = true;
        return;
      }
      this.selectedCannedResponse = item;
      this.$emit('replace', item.description);
      this.$emit('cannedSelected', item.id);
    },
    submitVariables() {
      let variables = {};
      const hasContextData = this.currentChat && this.currentContact;
      if (hasContextData) {
        variables = getMessageVariables({
          conversation: this.currentChat,
          contact: this.currentContact,
        });
      }
      const allVariables = {
        ...variables,
        ...this.userDefinedVariables,
      };
      const updatedMessage = replaceVariablesInMessage({
        message: this.selectedCannedResponse.description,
        variables: allVariables,
      });
      this.$emit('replace', updatedMessage);
      this.$emit('cannedSelected', this.selectedCannedResponse.id);
      this.showVariablePopup = false;
    },
    formatVariablePreview(rawMessage, variables = {}, userVariables = {}) {
      const allVariables = { ...variables, ...userVariables };
      return rawMessage.replace(/{{(.*?)}}/g, (_, varName) => {
        const name = varName.trim();
        const value = allVariables[name];
        if (value) {
          return `<span class="bg-yellow-100 dark:bg-yellow-700 px-1 rounded">${value}</span>`;
        }
        return `<span class="bg-red-100 dark:bg-red-700 px-1 rounded text-red-700 dark:text-white">[${name}]</span>`;
      });
    },
    closeModal() {
      this.showVariablePopup = false;
    },
    trySubmitOnEnter(e) {
      if (e.key === 'Enter' && this.isFormValid) {
        this.submitVariables();
      }
      if (e.key === 'Escape') {
        this.closeModal();
      }
    },
    disableSubmitButton() {
      return this.charactersRemaining < 0;
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div>
    <MentionBox
      v-if="items.length"
      :items="items"
      @mention-select="handleMentionClick"
    />
    <Modal v-model:show="showVariablePopup" :on-close="closeModal">
      <form
        class="flex flex-col space-y-4 w-full p-6 max-h-[90vh] overflow-y-auto"
        @submit.prevent="submitVariables"
        @keydown.enter.exact="trySubmitOnEnter($event)"
        @keydown.esc="closeModal"
      >
        <h2 class="text-xl font-semibold text-slate-900 dark:text-white">
          {{ $t('ONBOARDING.CANNED_RESPONSES.ENTER_VARIABLE_VALUES') }}
        </h2>

        <div v-for="key in undefinedVariables" :key="key" class="flex flex-col">
          <label
            :for="key"
            class="mb-1 text-sm font-medium text-slate-700 dark:text-slate-300 capitalize"
          >
            {{ key.replace(/[\_\.]/g, ' ') }}
          </label>
          <textarea
            :id="key"
            v-model="userDefinedVariables[key]"
            rows="3"
            class="input-variable resize-y"
            :placeholder="
              $t('ONBOARDING.CANNED_RESPONSES.VARIABLE_PLACEHOLDER', {
                variable: key,
              })
            "
            @keydown.stop
          />
        </div>

        <h3
          class="text-sm font-semibold text-slate-600 dark:text-slate-300 mb-2"
        >
          {{ $t('ONBOARDING.CANNED_RESPONSES.PREVIEW_MESSAGE') }}
        </h3>
        <div
          class="mt-6 p-4 border rounded-md bg-slate-50 dark:bg-slate-800 dark:border-slate-600"
        >
          <div
            v-if="isMessageLengthReachingThreshold"
            class="text-xs text-center"
          >
            <span :class="charLengthClass">
              {{ characterLengthWarning }}
            </span>
          </div>
          <p
            class="text-sm text-slate-800 dark:text-slate-100 whitespace-pre-wrap"
          >
            <span v-html="livePreviewMessage" />
          </p>
        </div>

        <div class="flex justify-end space-x-2 pt-4">
          <button
            type="button"
            class="button clear"
            @click.prevent="closeModal"
          >
            {{ $t('ONBOARDING.CANNED_RESPONSES.CANCEL') }}
          </button>
          <NextButton
            :label="$t('ONBOARDING.CANNED_RESPONSES.CONFIRM')"
            :disabled="!isFormValid || disableSubmitButton()"
            :is-loading="false"
            @click.prevent="submitVariables"
          />
        </div>
      </form>
    </Modal>
  </div>
</template>

<style scoped lang="scss">
.input-variable {
  min-height: 3rem;
  line-height: 1.4;
  @apply border rounded-md px-3 py-2 text-sm outline-none transition-colors;
  @apply bg-white text-slate-900 border-slate-300;
  @apply dark:bg-slate-800 dark:text-white dark:border-slate-600;

  &:focus {
    @apply border-woot-500 ring-1 ring-woot-500 dark:border-woot-400 dark:ring-woot-400;
  }
}
</style>
