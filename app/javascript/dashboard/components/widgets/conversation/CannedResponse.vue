<script>
import { mapGetters } from 'vuex';
import MentionBox from '../mentions/MentionBox.vue';
import Modal from 'dashboard/components/Modal.vue';
import WootSubmitButton from 'dashboard/components/buttons/FormSubmitButton.vue';
import {
  getMessageVariables,
  getUndefinedVariablesInMessage,
  replaceVariablesInMessage,
} from '@chatwoot/utils';

export default {
  components: { MentionBox, Modal, WootSubmitButton },
  props: {
    searchKey: {
      type: String,
      default: '',
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
      return this.$store.getters['contacts/getContact'](
        this.currentChat.meta.sender.id
      );
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
      const systemVariables = getMessageVariables({
        conversation: this.currentChat,
        contact: this.currentContact,
      });
      const allVariables = {
        ...systemVariables,
        ...this.userDefinedVariables,
      };
      return replaceVariablesInMessage({
        message: this.selectedCannedResponse.description,
        variables: allVariables,
      });
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
      const inboxId = this.currentChat.inbox_id;
      this.$store.dispatch('getCannedResponse', {
        searchKey: this.searchKey,
        inboxId,
      });
    },
    handleMentionClick(item = {}) {
      const variables = getMessageVariables({
        conversation: this.currentChat,
        contact: this.currentContact,
      });
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
      const systemVariables = getMessageVariables({
        conversation: this.currentChat,
        contact: this.currentContact,
      });
      const allVariables = {
        ...systemVariables,
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
        @submit.prevent="submitVariables"
        class="flex flex-col space-y-4 w-full p-6"
        @keydown.enter.prevent="trySubmitOnEnter"
      >
        <h2 class="text-xl font-semibold text-slate-900 dark:text-white">
          {{ $t('ONBOARDING.CANNED_RESPONSES.ENTER_VARIABLE_VALUES') }}
        </h2>

        <div v-for="key in undefinedVariables" :key="key" class="flex flex-col">
          <label
            :for="key"
            class="mb-1 text-sm font-medium text-slate-700 dark:text-slate-300"
          >
            {{ key }}
          </label>
          <input v-model="userDefinedVariables[key]" :id="key" type="text" class="input-variable"
            :placeholder="$t('ONBOARDING.CANNED_RESPONSES.VARIABLE_PLACEHOLDER', { variable: key })"
          />
        </div>

        <h3 class="text-sm font-semibold text-slate-600 dark:text-slate-300 mb-2">
          {{ $t('ONBOARDING.CANNED_RESPONSES.PREVIEW_MESSAGE') }}
        </h3>
        <div class="mt-6 p-4 border rounded-md bg-slate-50 dark:bg-slate-800 dark:border-slate-600">
          <p class="text-sm text-slate-800 dark:text-slate-100 whitespace-pre-wrap">
            {{ livePreviewMessage }}
          </p>
        </div>

        <div class="flex justify-end space-x-2 pt-4">
          <button type="button" class="button clear" @click.prevent="closeModal">
            {{ $t('ONBOARDING.CANNED_RESPONSES.CANCEL') }}
          </button>
          <WootSubmitButton
            :button-text="$t('ONBOARDING.CANNED_RESPONSES.CONFIRM')"
            :disabled="!isFormValid"
            :loading="false"
            @click.prevent="submitVariables"
          />
        </div>
      </form>
    </Modal>
  </div>
</template>

<style scoped lang="scss">
.input-variable {
  @apply border rounded-md px-3 py-2 text-sm outline-none transition-colors;
  @apply bg-white text-slate-900 border-slate-300;
  @apply dark:bg-slate-800 dark:text-white dark:border-slate-600;

  &:focus {
    @apply border-primary-500 ring-1 ring-primary-500 dark:border-primary-400 dark:ring-primary-400;
  }
}
</style>
