<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { vOnClickOutside } from '@vueuse/components';
import { EmailQuoteExtractor } from 'dashboard/components-next/message/bubbles/Email/removeReply.js';
import { debounce } from '@chatwoot/utils';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  searchContacts,
  createNewContact,
} from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';

import ForwardMessageForm from './components/ForwardMessageForm.vue';

const props = defineProps({
  forwardType: {
    type: String,
    default: 'email',
  },
  message: {
    type: Object,
    default: () => ({}),
  },
  content: {
    type: String,
    default: '',
  },
  inbox: {
    type: Object,
    default: () => ({}),
  },
  messageId: {
    type: Number,
    default: null,
  },
  attachments: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();

const contacts = ref([]);
const selectedContact = ref(null);
const isCreatingContact = ref(false);
const isSearching = ref(false);

const messageSignature = useMapGetter('getMessageSignature');
const currentChat = useMapGetter('getSelectedChat');
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');

const fromEmail = computed(() => props.inbox?.email);

const fullHTML = computed(() => {
  return (
    props.message?.htmlContent?.full ??
    props.message?.textContent?.full?.replace(/\n/g, '<br>')
  );
});

const unquotedHTML = computed(() =>
  EmailQuoteExtractor.extractQuotes(fullHTML.value)
);

const hasQuotedMessage = computed(() =>
  EmailQuoteExtractor.hasQuotes(fullHTML.value)
);

const textToShow = computed(() => {
  const text = props.message?.textContent?.full;
  return text?.replace(/\n/g, '<br>');
});

const onContactSearch = debounce(
  async query => {
    isSearching.value = true;
    contacts.value = [];
    try {
      contacts.value = await searchContacts(query);
      isSearching.value = false;
    } catch (error) {
      useAlert(t('FORWARD_MESSAGE_FORM.CONTACT_SEARCH.ERROR_MESSAGE'));
    } finally {
      isSearching.value = false;
    }
  },
  300,
  false
);

const handleClickOutside = () => {
  selectedContact.value = null;
  emit('close');
};

const handleForwardMessage = async ({ state }) => {
  try {
    const messagePayload = {
      conversationId: currentChat.value?.id,
      message: state.message,
      toEmails: selectedContact.value?.email,
      private: false,
      contentAttributes: {
        forwarded_message_id: props.messageId,
      },
      sender: {
        name: currentUser.value?.name,
        thumbnail: currentUser.value?.avatar_url,
      },
      files: globalConfig.value?.directUploadsEnabled
        ? state.attachedFiles.map(file => file.blobSignedId)
        : state.attachedFiles.map(file => file.resource.file),
    };
    await store.dispatch('createPendingMessageAndSend', messagePayload);
    emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
    emitter.emit(BUS_EVENTS.MESSAGE_SENT);
    // Close the forward message modal after sending
    emit('close');
  } catch (error) {
    const errorMessage =
      error?.response?.data?.error ||
      t('FORWARD_MESSAGE_FORM.FORWARD_MESSAGE.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const handleSelectedContact = async ({ value, action, ...rest }) => {
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
};
</script>

<template>
  <div
    v-on-click-outside="[
      handleClickOutside,
      // Fixed and edge case https://github.com/chatwoot/chatwoot/issues/10785
      // This will prevent closing the compose conversation modal when the editor Create link popup is open
      { ignore: ['div.ProseMirror-prompt'] },
    ]"
  >
    <ForwardMessageForm
      :forward-type="forwardType"
      :contacts="contacts"
      :selected-contact="selectedContact"
      :is-loading="isSearching"
      :is-creating-contact="isCreatingContact"
      :from-email="fromEmail"
      :message="message"
      :attachments="attachments"
      :message-signature="messageSignature"
      :content="content"
      :is-plain-email="!message || !Object.keys(message).length"
      :full-html="fullHTML"
      :unquoted-html="unquotedHTML"
      :text-to-show="textToShow"
      :has-quoted-message="hasQuotedMessage"
      @search-contacts="onContactSearch"
      @update-selected-contact="handleSelectedContact"
      @clear-selected-contact="selectedContact = null"
      @discard="emit('close')"
      @forward-message="handleForwardMessage"
    />
  </div>
</template>
