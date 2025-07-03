<script setup>
import { ref } from 'vue';
import { contacts, activeContact, emailInbox, currentUser } from './fixtures';
import ComposeNewConversationForm from '../ComposeNewConversationForm.vue';

const selectedContact = ref(activeContact);
const targetInbox = ref(emailInbox);

// Event handlers
const onSearchContacts = query => {
  console.log('Searching contacts:', query);
};

const onUpdateSelectedContact = contact => {
  console.log('Selected contact updated:', contact);
};

const onUpdateTargetInbox = inbox => {
  console.log('Target inbox updated:', inbox);
  targetInbox.value = inbox;
  console.log('Target inbox updated:', inbox);
};

const onClearSelectedContact = () => {
  console.log('Contact cleared');
};

const onCreateConversation = payload => {
  console.log('Creating conversation:', payload);
};

const onDiscard = () => {
  console.log('Form discarded');
};
</script>

<template>
  <Story
    title="Components/Compose/ComposeNewConversationForm"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="With all props">
      <div class="h-[600px] w-full relative">
        <ComposeNewConversationForm
          :contacts="contacts"
          contact-id=""
          :is-loading="false"
          :current-user="currentUser"
          :selected-contact="selectedContact"
          :target-inbox="targetInbox"
          :is-creating-contact="false"
          is-fetching-inboxes
          is-direct-uploads-enabled
          :contact-conversations-ui-flags="{ isCreating: false }"
          :contacts-ui-flags="{ isFetching: false }"
          class="!top-0"
          @search-contacts="onSearchContacts"
          @update-selected-contact="onUpdateSelectedContact"
          @update-target-inbox="onUpdateTargetInbox"
          @clear-selected-contact="onClearSelectedContact"
          @create-conversation="onCreateConversation"
          @discard="onDiscard"
        />
      </div>
    </Variant>

    <Variant title="With no target inbox">
      <div class="h-[200px] w-full relative">
        <ComposeNewConversationForm
          :contacts="contacts"
          contact-id=""
          :is-loading="false"
          :current-user="currentUser"
          :selected-contact="{ ...selectedContact, contactInboxes: [] }"
          :target-inbox="null"
          :is-creating-contact="false"
          :is-fetching-inboxes="false"
          is-direct-uploads-enabled
          :contact-conversations-ui-flags="{ isCreating: false }"
          :contacts-ui-flags="{ isFetching: false }"
          class="!top-0"
          @search-contacts="onSearchContacts"
          @update-selected-contact="onUpdateSelectedContact"
          @update-target-inbox="onUpdateTargetInbox"
          @clear-selected-contact="onClearSelectedContact"
          @create-conversation="onCreateConversation"
          @discard="onDiscard"
        />
      </div>
    </Variant>
  </Story>
</template>
