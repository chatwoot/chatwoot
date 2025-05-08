<script setup>
import { ref, computed, reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useI18n } from 'vue-i18n';
import { required } from '@vuelidate/validators';
import { buildContactableInboxesList } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper.js';
import {
  appendSignature,
  removeSignature,
} from 'dashboard/helper/editorHelper';

import ContactSelector from 'dashboard/components-next/NewConversation/components/ContactSelector.vue';
import ActionButtons from 'dashboard/components-next/NewConversation/components/ActionButtons.vue';
import AttachmentPreviews from 'dashboard/components-next/NewConversation/components/AttachmentPreviews.vue';
import EmailMessageEditor from './EmailMessageEditor.vue';
import AttachmentChips from 'next/message/chips/AttachmentChips.vue';

const props = defineProps({
  forwardType: { type: String, default: 'email' }, // eslint-disable-line vue/no-unused-properties
  contacts: { type: Array, default: () => [] },
  selectedContact: { type: Object, default: null },
  isLoading: { type: Boolean, default: false },
  isCreatingContact: { type: Boolean, default: false },
  fromEmail: { type: String, default: null },
  messageSignature: { type: String, default: '' },
  content: { type: String, default: '' },
  isPlainEmail: { type: Boolean, default: false },
  fullHtml: { type: String, default: '' },
  unquotedHtml: { type: String, default: '' },
  textToShow: { type: String, default: '' },
  hasQuotedMessage: { type: Boolean, default: false },
  attachments: { type: Array, default: () => [] },
});

const emit = defineEmits([
  'searchContacts',
  'updateSelectedContact',
  'clearSelectedContact',
  'discard',
  'forwardMessage',
]);

const { t } = useI18n();

const state = reactive({
  message: '',
  attachedFiles: [],
});

const showContactsDropdown = ref(false);

const contactableInboxesList = computed(() => {
  return buildContactableInboxesList(props.selectedContact?.contactInboxes);
});

const validationRules = computed(() => ({
  selectedContact: { required },
}));

const v$ = useVuelidate(validationRules, {
  selectedContact: computed(() => props.selectedContact),
});

const validationStates = computed(() => ({
  isContactInvalid:
    v$.value.selectedContact.$dirty && v$.value.selectedContact.$invalid,
}));

const handleContactSearch = value => {
  showContactsDropdown.value = true;
  emit('searchContacts', {
    keys: ['email'],
    query: value,
  });
};

const setSelectedContact = async ({ value, action, ...rest }) => {
  v$.value.$reset();
  emit('updateSelectedContact', { value, action, ...rest });
  showContactsDropdown.value = false;
};

const clearSelectedContact = () => {
  emit('clearSelectedContact');
  state.attachedFiles = [];
};

const handleDropdownUpdate = (type, value) => {
  showContactsDropdown.value = value;
};

const onClickInsertEmoji = emoji => {
  state.message += emoji;
};

const handleAddSignature = signature => {
  state.message = appendSignature(state.message, signature);
};

const handleRemoveSignature = signature => {
  state.message = removeSignature(state.message, signature);
};

const handleAttachFile = files => {
  state.attachedFiles = files;
};

const clearForm = () => {
  Object.assign(state, {
    message: '',
    attachedFiles: [],
  });
  v$.value.$reset();
};

const handleSendMessage = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  try {
    const success = await emit('forwardMessage', { state });
    if (success) {
      clearForm();
    }
  } catch (error) {
    // Form will not be cleared if conversation creation fails
  }
};
</script>

<template>
  <div
    class="w-[42rem] max-h-[31.25rem] divide-y divide-n-strong transition-all duration-300 ease-in-out top-full justify-between flex flex-col border border-n-strong shadow-sm backdrop-blur-[100px] rounded-xl overflow-hidden"
  >
    <div
      class="relative flex-1 rounded-t-xl px-4 py-3 overflow-y-visible bg-n-alpha-3"
    >
      <div class="flex items-baseline w-full gap-3 min-h-7">
        <label class="text-sm font-medium text-n-slate-11 whitespace-nowrap">
          {{ t('FORWARD_MESSAGE_FORM.FROM') }}
        </label>

        <div
          class="flex items-center gap-1.5 rounded-md bg-n-alpha-2 px-3 min-h-7 min-w-0"
        >
          <span class="text-sm truncate text-n-slate-12">
            {{ fromEmail }}
          </span>
        </div>
      </div>
    </div>
    <ContactSelector
      class="bg-n-alpha-3"
      :contacts="contacts"
      :selected-contact="selectedContact"
      :show-contacts-dropdown="showContactsDropdown"
      :is-loading="isLoading"
      :is-creating-contact="isCreatingContact"
      :contactable-inboxes-list="contactableInboxesList"
      :show-inboxes-dropdown="false"
      :has-errors="validationStates.isContactInvalid"
      @search-contacts="handleContactSearch"
      @set-selected-contact="setSelectedContact"
      @clear-selected-contact="clearSelectedContact"
      @update-dropdown="handleDropdownUpdate"
    />
    <div class="overflow-y-scroll">
      <EmailMessageEditor
        v-model="state.message"
        class="bg-n-alpha-3"
        :content="content"
        :is-plain-email="isPlainEmail"
        :has-quoted-message="hasQuotedMessage"
        :full-html="fullHtml"
        :unquoted-html="unquotedHtml"
        :text-to-show="textToShow"
      />
      <section
        v-if="Array.isArray(attachments) && attachments.length"
        class="px-4 pb-4 pt-2 !border-t-0 space-y-2 bg-n-alpha-3"
      >
        <AttachmentChips
          :attachments="attachments"
          class="gap-1 !justify-start"
        />
      </section>
    </div>
    <AttachmentPreviews
      v-if="state.attachedFiles.length > 0"
      :attachments="state.attachedFiles"
      class="bg-n-alpha-3"
      @update:attachments="state.attachedFiles = $event"
    />
    <ActionButtons
      class="bg-n-alpha-3 sticky bottom-0 backdrop-blur-[100px]"
      :attached-files="state.attachedFiles"
      is-email-or-web-widget-inbox
      channel-type="Channel::Email"
      :is-loading="false"
      :disable-send-button="false"
      has-selected-inbox
      :has-no-inbox="false"
      :is-dropdown-active="showContactsDropdown"
      :message-signature="messageSignature"
      @insert-emoji="onClickInsertEmoji"
      @add-signature="handleAddSignature"
      @remove-signature="handleRemoveSignature"
      @attach-file="handleAttachFile"
      @discard="$emit('discard')"
      @send-message="handleSendMessage"
    />
  </div>
</template>
