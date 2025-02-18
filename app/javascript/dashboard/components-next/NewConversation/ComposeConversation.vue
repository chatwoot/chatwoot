<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { vOnClickOutside } from '@vueuse/components';
import { useAlert } from 'dashboard/composables';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import { debounce } from '@chatwoot/utils';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import {
  searchContacts,
  createNewContact,
  fetchContactableInboxes,
  processContactableInboxes,
} from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';

import ComposeNewConversationForm from 'dashboard/components-next/NewConversation/components/ComposeNewConversationForm.vue';

const props = defineProps({
  alignPosition: {
    type: String,
    default: 'left',
  },
  contactId: {
    type: String,
    default: null,
  },
});

const store = useStore();
const { t } = useI18n();

const { fetchSignatureFlagFromUISettings } = useUISettings();

const contacts = ref([]);
const selectedContact = ref(null);
const targetInbox = ref(null);
const isCreatingContact = ref(false);
const isFetchingInboxes = ref(false);
const isSearching = ref(false);
const showComposeNewConversation = ref(false);

const contactById = useMapGetter('contacts/getContactById');
const contactsUiFlags = useMapGetter('contacts/getUIFlags');
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');
const uiFlags = useMapGetter('contactConversations/getUIFlags');
const messageSignature = useMapGetter('getMessageSignature');

const sendWithSignature = computed(() =>
  fetchSignatureFlagFromUISettings(targetInbox.value?.channelType)
);

const directUploadsEnabled = computed(
  () => globalConfig.value.directUploadsEnabled
);

const activeContact = computed(() => contactById.value(props.contactId));

const composePopoverClass = computed(() => {
  return props.alignPosition === 'right'
    ? 'absolute ltr:left-0 ltr:right-[unset] rtl:right-0 rtl:left-[unset]'
    : 'absolute rtl:left-0 rtl:right-[unset] ltr:right-0 ltr:left-[unset]';
});

const onContactSearch = debounce(
  async query => {
    isSearching.value = true;
    contacts.value = [];
    try {
      contacts.value = await searchContacts(query);
      isSearching.value = false;
    } catch (error) {
      useAlert(t('COMPOSE_NEW_CONVERSATION.CONTACT_SEARCH.ERROR_MESSAGE'));
    } finally {
      isSearching.value = false;
    }
  },
  300,
  false
);

const resetContacts = () => {
  contacts.value = [];
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
  if (contact?.id) {
    isFetchingInboxes.value = true;
    try {
      const contactableInboxes = await fetchContactableInboxes(contact.id);
      selectedContact.value.contactInboxes = contactableInboxes;
      isFetchingInboxes.value = false;
    } catch (error) {
      isFetchingInboxes.value = false;
    }
  }
};

const handleTargetInbox = inbox => {
  targetInbox.value = inbox;
  resetContacts();
};

const clearSelectedContact = () => {
  selectedContact.value = null;
  targetInbox.value = null;
};

const closeCompose = () => {
  showComposeNewConversation.value = false;
  selectedContact.value = null;
  targetInbox.value = null;
  resetContacts();
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
    closeCompose();
    useAlert(t('COMPOSE_NEW_CONVERSATION.FORM.SUCCESS_MESSAGE'), action);
    return true; // Return success
  } catch (error) {
    useAlert(
      error instanceof ExceptionWithMessage
        ? error.data
        : t('COMPOSE_NEW_CONVERSATION.FORM.ERROR_MESSAGE')
    );
    return false; // Return failure
  }
};

const toggle = () => {
  showComposeNewConversation.value = !showComposeNewConversation.value;
};

watch(
  activeContact,
  () => {
    if (activeContact.value && props.contactId) {
      const contactInboxes = activeContact.value?.contactInboxes || [];
      selectedContact.value = {
        ...activeContact.value,
        contactInboxes: processContactableInboxes(contactInboxes),
      };
    }
  },
  { immediate: true, deep: true }
);

onMounted(() => resetContacts());

const keyboardEvents = {
  Escape: {
    action: () => {
      if (showComposeNewConversation.value) {
        showComposeNewConversation.value = false;
      }
    },
  },
};

useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div
    v-on-click-outside="() => (showComposeNewConversation = false)"
    class="relative"
    :class="{
      'z-40': showComposeNewConversation,
    }"
  >
    <slot
      name="trigger"
      :is-open="showComposeNewConversation"
      :toggle="toggle"
    />
    <ComposeNewConversationForm
      v-if="showComposeNewConversation"
      :contacts="contacts"
      :contact-id="contactId"
      :is-loading="isSearching"
      :current-user="currentUser"
      :selected-contact="selectedContact"
      :target-inbox="targetInbox"
      :is-creating-contact="isCreatingContact"
      :is-fetching-inboxes="isFetchingInboxes"
      :is-direct-uploads-enabled="directUploadsEnabled"
      :contact-conversations-ui-flags="uiFlags"
      :contacts-ui-flags="contactsUiFlags"
      :class="composePopoverClass"
      :message-signature="messageSignature"
      :send-with-signature="sendWithSignature"
      @search-contacts="onContactSearch"
      @reset-contact-search="resetContacts"
      @update-selected-contact="handleSelectedContact"
      @update-target-inbox="handleTargetInbox"
      @clear-selected-contact="clearSelectedContact"
      @create-conversation="createConversation"
      @discard="closeCompose"
    />
  </div>
</template>
