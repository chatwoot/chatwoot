<script setup>
import { reactive, watch, ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import { useVuelidate } from '@vuelidate/core';
import { required, requiredIf } from '@vuelidate/validators';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  appendSignature,
  removeSignature,
} from 'dashboard/helper/editorHelper';
import {
  buildContactableInboxesList,
  createNewContact,
  fetchContactableInboxes,
  prepareNewMessagePayload,
  prepareWhatsAppMessagePayload,
  processContactableInboxes,
} from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper.js';

import ContactSelector from './components/ContactSelector.vue';
import InboxSelector from './components/InboxSelector.vue';
import EmailOptions from './components/EmailOptions.vue';
import MessageEditor from './components/MessageEditor.vue';
import ActionButtons from './components/ActionButtons.vue';
import InboxEmptyState from './components/InboxEmptyState.vue';

const props = defineProps({
  contacts: {
    type: Array,
    default: () => [],
  },
  contactId: {
    type: String,
    default: null,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['searchContacts', 'discard', 'success']);

const store = useStore();
const { t } = useI18n();

const showContactsDropdown = ref(false);
const showInboxesDropdown = ref(false);
const showCcEmailsDropdown = ref(false);
const showBccEmailsDropdown = ref(false);
const isCreatingContact = ref(false);
const isFetchingInboxes = ref(false);

const contactById = useMapGetter('contacts/getContactById');
const contactsUiFlags = useMapGetter('contacts/getUIFlags');
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');
const uiFlags = useMapGetter('contactConversations/getUIFlags');
const activeContact = computed(() => contactById.value(props.contactId));
const directUploadsEnabled = computed(
  () => globalConfig.value.directUploadsEnabled
);

const isCreating = computed(() => uiFlags.value.isCreating);

const selectedContact = ref(null);
const targetInbox = ref(null);

const state = reactive({
  message: '',
  subject: '',
  ccEmails: '',
  bccEmails: '',
  attachedFiles: [],
});

const showBccInput = ref(false);

const inboxTypes = computed(() => ({
  isEmail: targetInbox.value?.channelType === INBOX_TYPES.EMAIL,
  isTwilio: targetInbox.value?.channelType === INBOX_TYPES.TWILIO,
  isWhatsapp: targetInbox.value?.channelType === INBOX_TYPES.WHATSAPP,
  isWebWidget: targetInbox.value?.channelType === INBOX_TYPES.WEB,
  isApi: targetInbox.value?.channelType === INBOX_TYPES.API,
  isEmailOrWebWidget:
    targetInbox.value?.channelType === INBOX_TYPES.EMAIL ||
    targetInbox.value?.channelType === INBOX_TYPES.WEB,
  isTwilioSMS:
    targetInbox.value?.channelType === INBOX_TYPES.TWILIO &&
    targetInbox.value?.medium === 'sms',
}));

const whatsappMessageTemplates = computed(() =>
  Object.keys(targetInbox.value?.messageTemplates || {}).length
    ? targetInbox.value.messageTemplates
    : []
);

const inboxChannelType = computed(() => targetInbox.value?.channelType || '');

const validationRules = computed(() => ({
  selectedContact: { required },
  targetInbox: { required },
  message: { required: requiredIf(!inboxTypes.value.isWhatsapp) },
  subject: { required: requiredIf(inboxTypes.value.isEmail) },
}));

const v$ = useVuelidate(validationRules, {
  selectedContact,
  targetInbox,
  message: computed(() => state.message),
  subject: computed(() => state.subject),
});

const validationStates = computed(() => ({
  isContactInvalid:
    v$.value.selectedContact.$dirty && v$.value.selectedContact.$invalid,
  isInboxInvalid: v$.value.targetInbox.$dirty && v$.value.targetInbox.$invalid,
  isSubjectInvalid: v$.value.subject.$dirty && v$.value.subject.$invalid,
  isMessageInvalid: v$.value.message.$dirty && v$.value.message.$invalid,
}));

const newMessagePayload = () => {
  const { message, subject, ccEmails, bccEmails, attachedFiles } = state;
  return prepareNewMessagePayload({
    targetInbox: targetInbox.value,
    selectedContact: selectedContact.value,
    message,
    subject,
    ccEmails,
    bccEmails,
    currentUser: currentUser.value,
    attachedFiles,
    directUploadsEnabled: directUploadsEnabled.value,
  });
};

const contactableInboxesList = computed(() => {
  return buildContactableInboxesList(selectedContact.value?.contactInboxes);
});

const showNoInboxAlert = computed(() => {
  return (
    selectedContact.value &&
    contactableInboxesList.value.length === 0 &&
    !contactsUiFlags.value.isFetchingInboxes &&
    !isFetchingInboxes.value
  );
});

const handleContactSearch = value => {
  emit('searchContacts', value);
};

const handleDropdownUpdate = (type, value) => {
  if (type === 'cc') {
    showCcEmailsDropdown.value = value;
  } else if (type === 'bcc') {
    showBccEmailsDropdown.value = value;
  } else {
    showContactsDropdown.value = value;
  }
};

const toggleBccInput = () => {
  showBccInput.value = !showBccInput.value;
};

const searchCcEmails = value => {
  showCcEmailsDropdown.value = true;
  emit('searchContacts', value);
};

const searchBccEmails = value => {
  showBccEmailsDropdown.value = true;
  emit('searchContacts', value);
};

const setSelectedContact = async ({ value, action, ...rest }) => {
  try {
    v$.value.$reset();
    let contact;

    if (action === 'create') {
      isCreatingContact.value = true;
      try {
        contact = await createNewContact(value);
        isCreatingContact.value = false;
      } catch (error) {
        isCreatingContact.value = false;
        return;
      }
    } else {
      contact = rest;
    }
    selectedContact.value = contact;
    showContactsDropdown.value = false;

    // Only proceed with fetching inboxes if we have a contact
    if (contact?.id) {
      isFetchingInboxes.value = true;
      const contactableInboxes = await fetchContactableInboxes(contact.id);
      selectedContact.value.contactInboxes = contactableInboxes;
      showInboxesDropdown.value = true;
      isFetchingInboxes.value = false;
    }
  } catch (error) {
    // Reset states in case of error
    isCreatingContact.value = false;
    showContactsDropdown.value = false;
  }
};

const handleInboxAction = ({ value, action, ...rest }) => {
  v$.value.$reset();
  targetInbox.value = {
    ...rest,
  };
  showInboxesDropdown.value = false;
};

const removeTargetInbox = value => {
  v$.value.$reset();
  targetInbox.value = value;
};

const clearSelectedContact = () => {
  selectedContact.value = null;
  targetInbox.value = null;
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
    subject: '',
    ccEmails: '',
    bccEmails: '',
    attachedFiles: [],
  });
  v$.value.$reset();
};

const createConversation = async ({ payload, isFromWhatsApp }) => {
  try {
    const data = await store.dispatch('contactConversations/create', {
      params: payload,
      isFromWhatsApp,
    });
    const action = {
      type: 'link',
      to: `/app/accounts/${data.account_id}/conversations/${data.id}`,
      message: t('COMPOSE_NEW_CONVERSATION.FORM.GO_TO_CONVERSATION'),
    };
    emit('success');
    useAlert(t('COMPOSE_NEW_CONVERSATION.FORM.SUCCESS_MESSAGE'), action);
  } catch (error) {
    useAlert(
      error instanceof ExceptionWithMessage
        ? error.data
        : t('COMPOSE_NEW_CONVERSATION.FORM.ERROR_MESSAGE')
    );
  }
};

const handleSendMessage = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid) return;

  await createConversation({
    payload: newMessagePayload(),
    isFromWhatsApp: false,
  });
  emit('discard');
  clearForm();
};

const handleSendWhatsappMessage = async ({ message, templateParams }) => {
  const whatsappMessagePayload = prepareWhatsAppMessagePayload({
    targetInbox: targetInbox.value,
    selectedContact: selectedContact.value,
    message,
    templateParams,
    currentUser: currentUser.value,
  });
  await createConversation({
    payload: whatsappMessagePayload,
    isFromWhatsApp: true,
  });
  emit('discard');
};

watch(
  activeContact,
  () => {
    if (activeContact.value && props.contactId) {
      selectedContact.value = {
        ...activeContact.value,
        contactInboxes: processContactableInboxes(
          activeContact.value?.contactInboxes
        ),
      };
    }
  },
  { immediate: true, deep: true }
);
</script>

<template>
  <div
    class="absolute right-0 w-[670px] mt-2 divide-y divide-n-strong overflow-visible transition-all duration-300 ease-in-out top-full justify-between flex flex-col bg-n-alpha-3 border border-n-strong shadow-sm backdrop-blur-[100px] rounded-xl"
  >
    <ContactSelector
      :contacts="contacts"
      :selected-contact="selectedContact"
      :show-contacts-dropdown="showContactsDropdown"
      :is-loading="isLoading"
      :is-creating-contact="isCreatingContact"
      :contact-id="contactId"
      :contactable-inboxes-list="contactableInboxesList"
      :show-inboxes-dropdown="showInboxesDropdown"
      :has-errors="validationStates.isContactInvalid"
      @search-contacts="handleContactSearch"
      @set-selected-contact="setSelectedContact"
      @clear-selected-contact="clearSelectedContact"
      @update-dropdown="handleDropdownUpdate"
    />
    <InboxEmptyState v-if="showNoInboxAlert" />
    <InboxSelector
      v-else
      :target-inbox="targetInbox"
      :selected-contact="selectedContact"
      :show-inboxes-dropdown="showInboxesDropdown"
      :contactable-inboxes-list="contactableInboxesList"
      :has-errors="validationStates.isInboxInvalid"
      @update-inbox="removeTargetInbox"
      @toggle-dropdown="showInboxesDropdown = $event"
      @handle-inbox-action="handleInboxAction"
    />

    <EmailOptions
      v-if="inboxTypes.isEmail"
      v-model:cc-emails="state.ccEmails"
      v-model:bcc-emails="state.bccEmails"
      v-model:subject="state.subject"
      :contacts="contacts"
      :show-cc-emails-dropdown="showCcEmailsDropdown"
      :show-bcc-emails-dropdown="showBccEmailsDropdown"
      :show-bcc-input="showBccInput"
      :is-loading="isLoading"
      :has-errors="validationStates.isSubjectInvalid"
      @search-cc-emails="searchCcEmails"
      @search-bcc-emails="searchBccEmails"
      @toggle-bcc="toggleBccInput"
      @update-dropdown="handleDropdownUpdate"
    />

    <MessageEditor
      v-if="!inboxTypes.isWhatsapp && !showNoInboxAlert"
      v-model="state.message"
      :is-email-or-web-widget-inbox="inboxTypes.isEmailOrWebWidget"
      :has-errors="validationStates.isMessageInvalid"
    />

    <ActionButtons
      :is-whatsapp-inbox="inboxTypes.isWhatsapp"
      :is-email-or-web-widget-inbox="inboxTypes.isEmailOrWebWidget"
      :is-twilio-sms-inbox="inboxTypes.isTwilioSMS"
      :message-templates="whatsappMessageTemplates"
      :channel-type="inboxChannelType"
      :is-loading="isCreating"
      :disable-send-button="isCreating"
      :has-no-inbox="showNoInboxAlert"
      @insert-emoji="onClickInsertEmoji"
      @add-signature="handleAddSignature"
      @remove-signature="handleRemoveSignature"
      @attach-file="handleAttachFile"
      @discard="$emit('discard')"
      @send-message="handleSendMessage"
      @send-whatsapp-message="handleSendWhatsappMessage"
    />
  </div>
</template>
