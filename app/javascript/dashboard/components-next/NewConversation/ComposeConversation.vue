<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { debounce } from '@chatwoot/utils';
import {
  searchContacts,
  createNewContact,
  fetchContactableInboxes,
  processContactableInboxes,
} from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper.js';

import ComposeNewConversationForm from 'dashboard/components-next/NewConversation/components/ComposeNewConversationForm.vue';

const route = useRoute();
const { t } = useI18n();

const contacts = ref([]);
const selectedContact = ref(null);
const targetInbox = ref(null);

const isCreatingContact = ref(false);
const isFetchingInboxes = ref(false);

const isSearching = ref(false);
const showComposeNewConversation = ref(false);

const contactById = useMapGetter('contacts/getContactById');
const contactId = computed(() => route.params.contactId || null);
const activeContact = computed(() => contactById.value(contactId.value));

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

const handleSelectedContact = async ({ value, action, ...rest }) => {
  try {
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
      const contactableInboxes = await fetchContactableInboxes(contact.id);
      selectedContact.value.contactInboxes = contactableInboxes;
      isFetchingInboxes.value = false;
    }
  } catch (error) {
    isCreatingContact.value = false;
  }
};

const handleTargetInbox = inbox => {
  targetInbox.value = inbox;
};

const clearSelectedContact = () => {
  selectedContact.value = null;
  targetInbox.value = null;
};

const closeCompose = () => {
  showComposeNewConversation.value = false;
  selectedContact.value = null;
  targetInbox.value = null;
};

const toggle = () => {
  showComposeNewConversation.value = !showComposeNewConversation.value;
};

watch(
  activeContact,
  () => {
    if (activeContact.value && contactId.value) {
      // Add null check for contactInboxes
      const contactInboxes = activeContact.value?.contactInboxes || [];
      selectedContact.value = {
        ...activeContact.value,
        contactInboxes: processContactableInboxes(contactInboxes),
      };
    }
  },
  { immediate: true, deep: true }
);

onMounted(() => {
  onContactSearch('');
});
</script>

<template>
  <div class="relative">
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
      :selected-contact="selectedContact"
      :target-inbox="targetInbox"
      :is-creating-contact="isCreatingContact"
      :is-fetching-inboxes="isFetchingInboxes"
      @search-contacts="onContactSearch"
      @update-selected-contact="handleSelectedContact"
      @update-target-inbox="handleTargetInbox"
      @clear-selected-contact="clearSelectedContact"
      @discard="closeCompose"
    />
  </div>
</template>
