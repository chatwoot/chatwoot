<script setup>
import { reactive, watch, ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import camelcaseKeys from 'camelcase-keys';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  appendSignature,
  removeSignature,
} from 'dashboard/helper/editorHelper';

import ContactAPI from 'dashboard/api/contacts';
import ContactSelector from './components/ContactSelector.vue';
import InboxSelector from './components/InboxSelector.vue';
import EmailOptions from './components/EmailOptions.vue';
import MessageEditor from './components/MessageEditor.vue';
import ActionButtons from './components/ActionButtons.vue';

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

const contactById = useMapGetter('contacts/getContactById');
const currentUser = useMapGetter('getCurrentUser');
const activeContact = computed(() => contactById.value(props.contactId));

const selectedContact = ref(null);
const targetInbox = ref(null);

const state = reactive({
  message: '',
  subject: '',
  ccEmails: '',
  bccEmails: '',
});

const showBccInput = ref(false);

const isEmailInbox = computed(() => {
  return targetInbox.value?.channelType === INBOX_TYPES.EMAIL;
});

const isTwilioInbox = computed(() => {
  return targetInbox.value?.channelType === INBOX_TYPES.TWILIO;
});

const isWhatsappInbox = computed(() => {
  return targetInbox.value?.channelType === INBOX_TYPES.WHATSAPP;
});

const isWebWidgetInbox = computed(() => {
  return targetInbox.value?.channelType === INBOX_TYPES.WEB;
});

const isApiInbox = computed(() => {
  return targetInbox.value?.channelType === INBOX_TYPES.API;
});

const isEmailOrWebWidgetInbox = computed(() => {
  return isEmailInbox.value || isWebWidgetInbox.value;
});

const whatsappMessageTemplates = computed(() => {
  return targetInbox.value?.messageTemplates;
});

const inboxChannelType = computed(() => {
  return targetInbox.value?.channelType || '';
});

const newMessagePayload = () => {
  const payload = {
    inboxId: targetInbox.value.id,
    sourceId: targetInbox.value.sourceId,
    contactId: Number(selectedContact.value.id),
    message: { content: state.message },
    assigneeId: currentUser.value.id,
  };

  //     if (this.attachedFiles && this.attachedFiles.length) {
  //         payload.files = [];
  //   setAttachmentPayload(payload);
  // }

  if (state.subject) {
    payload.mailSubject = state.subject;
  }

  if (state.ccEmails) {
    payload.message.cc_emails = state.ccEmails;
  }

  if (state.bccEmails) {
    payload.message.bcc_emails = state.bccEmails;
  }
  return payload;
};

const generateLabelForContactableInboxesList = ({
  name,
  email,
  channelType,
  phoneNumber,
}) => {
  if (channelType === INBOX_TYPES.EMAIL) {
    return `${name} (${email})`;
  }
  if (
    channelType === INBOX_TYPES.TWILIO ||
    channelType === INBOX_TYPES.WHATSAPP
  ) {
    return `${name} (${phoneNumber})`;
  }
  if (channelType === INBOX_TYPES.API) {
    return `${name} (API)`;
  }
  return name;
};

const contactableInboxesList = computed(() => {
  return selectedContact.value?.contactInboxes?.map(
    ({ name, id, email, channelType, phoneNumber, ...rest }) => ({
      id,
      label: generateLabelForContactableInboxesList({
        name,
        email,
        channelType,
        phoneNumber,
      }),
      action: 'inbox',
      value: id,
      name,
      email,
      phoneNumber,
      channelType,
      ...rest,
    })
  );
});

const getCapitalizedNameFromEmail = email => {
  const name = email.match(/^([^@]*)@/)?.[1] || email.split('@')[0];
  return name.charAt(0).toUpperCase() + name.slice(1);
};

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
    let contact;

    if (action === 'create') {
      isCreatingContact.value = true;
      const payload = {
        name: getCapitalizedNameFromEmail(value),
        email: value,
      };

      try {
        const {
          data: {
            payload: { contact: newContact },
          },
        } = await ContactAPI.create(payload);
        contact = camelcaseKeys(newContact, {
          deep: true,
        });
      } catch (error) {
        isCreatingContact.value = false;
        return;
      }

      selectedContact.value = contact;
      isCreatingContact.value = false;
    } else {
      contact = rest;
      selectedContact.value = contact;
    }

    showContactsDropdown.value = false;

    // Only proceed with fetching inboxes if we have a contact
    if (contact?.id) {
      const {
        data: { payload: inboxes = [] },
      } = await ContactAPI.getContactableInboxes(contact.id);

      const contactableInboxes = inboxes.map(inbox => ({
        ...inbox.inbox,
        sourceId: inbox.source_id,
      }));

      selectedContact.value.contactInboxes = camelcaseKeys(contactableInboxes, {
        deep: true,
      });
      showInboxesDropdown.value = true;
    }
  } catch (error) {
    // console.error('Error in setSelectedContact:', error);
    // Reset states in case of error
    isCreatingContact.value = false;
    showContactsDropdown.value = false;
  }
};

const handleInboxAction = ({ value, action, ...rest }) => {
  targetInbox.value = {
    ...rest,
  };
  showInboxesDropdown.value = false;
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

const clearForm = () => {
  state.message = '';
  state.subject = '';
  state.ccEmails = '';
  state.bccEmails = '';
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
      message: t('NEW_CONVERSATION.FORM.GO_TO_CONVERSATION'),
    };
    emit('success');
    useAlert(t('NEW_CONVERSATION.FORM.SUCCESS_MESSAGE'), action);
  } catch (error) {
    if (error instanceof ExceptionWithMessage) {
      useAlert(error.data);
    } else {
      useAlert(t('NEW_CONVERSATION.FORM.ERROR_MESSAGE'));
    }
  }
};

const handleSendMessage = async () => {
  await createConversation({
    payload: newMessagePayload(),
    isFromWhatsApp: false,
  });
  emit('discard');
  clearForm();
};

const prepareWhatsAppMessagePayload = ({ message, templateParams }) => {
  const payload = {
    inboxId: targetInbox.value.id,
    sourceId: targetInbox.value.sourceId,
    contactId: selectedContact.value.id,
    message: { content: message, template_params: templateParams },
    assigneeId: currentUser.value.id,
  };
  return payload;
};

const handleSendWhatsappMessage = async payload => {
  const whatsappPayload = prepareWhatsAppMessagePayload(payload);
  await createConversation({ payload: whatsappPayload, isFromWhatsApp: true });
  emit('discard');
};

watch(
  activeContact,
  () => {
    if (activeContact.value && props.contactId) {
      selectedContact.value = {
        ...activeContact.value,
        contactInboxes: activeContact.value?.contactInboxes.map(inbox => ({
          ...inbox.inbox,
          sourceId: inbox.sourceId,
        })),
      };
    }
  },
  { immediate: true, deep: true }
);
</script>

<template>
  <div
    class="divide-y divide-n-strong absolute right-0 w-[670px] mt-2 overflow-visible transition-all duration-300 ease-in-out top-full justify-between flex flex-col bg-n-alpha-3 border border-n-strong shadow-sm backdrop-blur-[100px] rounded-xl"
  >
    <div class="flex flex-col divide-y divide-n-strong">
      <ContactSelector
        :contacts="contacts"
        :selected-contact="selectedContact"
        :show-contacts-dropdown="showContactsDropdown"
        :is-loading="isLoading"
        :is-creating-contact="isCreatingContact"
        :contact-id="contactId"
        :contactable-inboxes-list="contactableInboxesList"
        :show-inboxes-dropdown="showInboxesDropdown"
        @search-contacts="handleContactSearch"
        @set-selected-contact="setSelectedContact"
        @clear-selected-contact="clearSelectedContact"
        @update-dropdown="handleDropdownUpdate"
      />

      <InboxSelector
        :target-inbox="targetInbox"
        :selected-contact="selectedContact"
        :show-inboxes-dropdown="showInboxesDropdown"
        :contactable-inboxes-list="contactableInboxesList"
        @update-inbox="targetInbox = $event"
        @toggle-dropdown="showInboxesDropdown = $event"
        @handle-inbox-action="handleInboxAction"
      />

      <EmailOptions
        v-if="isEmailInbox"
        v-model:cc-emails="state.ccEmails"
        v-model:bcc-emails="state.bccEmails"
        v-model:subject="state.subject"
        :contacts="contacts"
        :show-cc-emails-dropdown="showCcEmailsDropdown"
        :show-bcc-emails-dropdown="showBccEmailsDropdown"
        :show-bcc-input="showBccInput"
        :is-loading="isLoading"
        @search-cc-emails="searchCcEmails"
        @search-bcc-emails="searchBccEmails"
        @toggle-bcc="toggleBccInput"
        @update-dropdown="handleDropdownUpdate"
      />

      <MessageEditor
        v-model="state.message"
        :is-email-or-web-widget-inbox="isEmailOrWebWidgetInbox"
        :is-whatsapp-inbox="isWhatsappInbox"
      />
    </div>

    <ActionButtons
      :is-whatsapp-inbox="isWhatsappInbox"
      :is-email-or-web-widget-inbox="isEmailOrWebWidgetInbox"
      :is-twilio-inbox="isTwilioInbox"
      :is-api-inbox="isApiInbox"
      :message-templates="whatsappMessageTemplates"
      :channel-type="inboxChannelType"
      @discard="$emit('discard')"
      @send-message="handleSendMessage"
      @send-whatsapp-message="handleSendWhatsappMessage"
      @insert-emoji="onClickInsertEmoji"
      @add-signature="handleAddSignature"
      @remove-signature="handleRemoveSignature"
    />
  </div>
</template>
