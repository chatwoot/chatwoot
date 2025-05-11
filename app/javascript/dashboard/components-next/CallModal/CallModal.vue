<template>
  <div class="w-[42rem] divide-y divide-n-strong overflow-visible transition-all duration-300 ease-in-out top-full justify-between flex flex-col bg-n-alpha-3 border border-n-strong shadow-sm backdrop-blur-[100px] rounded-xl">
    <div class="px-4 py-3 flex items-center">
      <h3 class="text-base font-medium">{{ $t('CALL_MODAL.START_CALL') }}</h3>
    </div>
    
    <!-- Inbox Selector (First) -->
    <div class="flex items-center flex-1 w-full gap-3 px-4 py-3 overflow-y-visible">
      <label class="mb-0.5 text-sm font-medium text-n-slate-11 whitespace-nowrap">
        {{ $t('CALL_MODAL.VIA') }}
      </label>
      
      <div
        v-if="selectedInbox"
        class="flex items-center gap-1.5 rounded-md bg-n-alpha-2 truncate ltr:pl-3 rtl:pr-3 ltr:pr-1 rtl:pl-1 h-7 min-w-0"
      >
        <span class="text-sm truncate text-n-slate-12 flex items-center gap-2">
          <span class="i-ri-phone-fill text-n-slate-11"></span>
          {{ selectedInbox.name }} - {{ selectedInbox.phoneNumber }}
        </span>
        <Button
          variant="ghost"
          icon="i-lucide-x"
          color="slate"
          size="xs"
          class="flex-shrink-0"
          @click="selectedInbox = null"
        />
      </div>
      
      <div
        v-else
        v-on-click-outside="() => showInboxDropdown = false"
        class="relative flex items-center h-7"
      >
        <Button
          :label="$t('CALL_MODAL.SELECT_INBOX')"
          variant="link"
          size="sm"
          color="slate"
          class="hover:!no-underline"
          @click="showInboxDropdown = !showInboxDropdown"
        />
        <DropdownMenu
          v-if="voiceInboxesList.length > 0 && showInboxDropdown"
          :menu-items="voiceInboxesList"
          class="left-0 z-[100] top-8 overflow-y-auto max-h-60 w-fit max-w-sm dark:!outline-n-slate-5"
          @action="selectInbox($event)"
        />
      </div>
    </div>
    
    <!-- Contact Selector -->
    <ContactSelector
      :contacts="contacts"
      :selected-contact="selectedContact"
      :show-contacts-dropdown="showContactsDropdown"
      :is-loading="isSearching"
      :is-creating-contact="false"
      :contact-id="null"
      :contactable-inboxes-list="[]"
      :show-inboxes-dropdown="false"
      :has-errors="false"
      @search-contacts="handleContactSearch"
      @set-selected-contact="handleSelectedContact"
      @clear-selected-contact="clearSelectedContact"
      @update-dropdown="handleDropdownUpdate"
    />

    <!-- Action buttons -->
    <div class="flex items-center justify-end w-full h-[3.25rem] gap-2 px-4 py-3">
      <Button
        :label="$t('CALL_MODAL.CANCEL')"
        variant="faded"
        color="slate"
        size="sm"
        class="!text-xs font-medium"
        @click="$emit('close')"
      />
      <Button
        :label="$t('CALL_MODAL.CALL')"
        icon="i-ri-phone-fill"
        size="sm"
        class="!text-xs font-medium"
        :disabled="!selectedInbox || !selectedContact || isLoading"
        :is-loading="isLoading"
        @click="makeCall"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { debounce } from '@chatwoot/utils';
import { vOnClickOutside } from '@vueuse/components';
import ContactAPI from 'dashboard/api/contacts';
import VoiceAPI from 'dashboard/api/channels/voice';
import camelcaseKeys from 'camelcase-keys';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ContactSelector from 'dashboard/components-next/NewConversation/components/ContactSelector.vue';
import axios from 'axios';

const { t } = useI18n();
const store = useStore();

const emit = defineEmits(['close']);

const selectedContact = ref(null);
const selectedInbox = ref(null);
const showContactsDropdown = ref(false);
const showInboxDropdown = ref(false);
const contacts = ref([]);
const isSearching = ref(false);
const isLoading = ref(false);

const inboxes = useMapGetter('inboxes/getInboxes');

const voiceInboxesList = computed(() => {
  return inboxes.value
    .filter(inbox => inbox.channel_type === INBOX_TYPES.VOICE)
    .map(inbox => ({
      id: inbox.id,
      title: `${inbox.name}`,
      subtitle: inbox.phone_number,
      label: `${inbox.name} - ${inbox.phone_number}`,
      action: 'select-inbox',
      value: inbox.id,
      sourceId: inbox.id,
      phoneNumber: inbox.phone_number,
      name: inbox.name,
      icon: 'i-ri-phone-fill',
    }));
});

// Auto-select the first available voice inbox
watch(voiceInboxesList, (newList) => {
  if (newList.length > 0 && !selectedInbox.value) {
    selectedInbox.value = newList[0];
  }
}, { immediate: true });

const selectInbox = item => {
  const inbox = voiceInboxesList.value.find(i => i.value === item.value);
  if (inbox) {
    selectedInbox.value = inbox;
    showInboxDropdown.value = false;
  }
};

const handleSelectedContact = ({ value, action, ...rest }) => {
  // If this is a direct call to a phone number
  if (action === 'create' && value.match(/^\+?[0-9\s\-()]+$/)) {
    selectedContact.value = {
      id: 'direct-call',
      name: t('CALL_MODAL.CALL_DIRECTLY'),
      sourceId: 'direct-call',
      phoneNumber: value,
      action: 'contact',
    };
  } else {
    // For existing contacts, make sure we're capturing their ID properly
    console.log('Contact selected from dropdown:', { value, action, ...rest });
    selectedContact.value = {
      ...rest,
      sourceId: rest.id || rest.value || value // Make sure we have the ID in sourceId
    };
  }
  showContactsDropdown.value = false;
};

const handleDropdownUpdate = (type, value) => {
  showContactsDropdown.value = value;
};

const clearSelectedContact = () => {
  selectedContact.value = null;
};

// This function gets called from the ContactSelector component
const handleContactSearch = value => {
  showContactsDropdown.value = true;
  // Pass all the needed keys for search when using the value sent directly
  debouncedSearchContacts(value);
};

const debouncedSearchContacts = debounce(async query => {
  if (!query || query.length < 2) {
    contacts.value = [];
    return;
  }

  isSearching.value = true;
  try {
    // Use the simple search endpoint since it's more reliable for this use case
    const { data } = await ContactAPI.search(query);

    console.log('Search response:', data); // Log the search response

    // Ensure contacts.value is an array and convert to camelCase
    const searchResults = data?.payload ? camelcaseKeys(data.payload, { deep: true }) : [];

    // Filter to only include contacts with phone numbers
    const contactsWithPhone = searchResults.filter(contact => contact.phoneNumber);

    // Map the contacts to ensure they have sourceId set to ID for consistency
    contacts.value = contactsWithPhone.map(contact => ({
      ...contact,
      sourceId: contact.id, // Make sure sourceId is set
      value: contact.id // Make sure value is set for TagInput
    }));

    // If it looks like a phone number, add option to call directly
    if (query.match(/^\+?[0-9\s\-()]+$/) && !contacts.value.some(c => c.phoneNumber === query)) {
      contacts.value.push({
        id: 'direct-call',
        name: t('CALL_MODAL.CALL_DIRECTLY'),
        phoneNumber: query,
        sourceId: 'direct-call',
        value: 'direct-call'
      });
    }

    console.log('Processed contacts for dropdown:', contacts.value);
  } catch (error) {
    console.error('Error searching contacts:', error);
    contacts.value = []; // Ensure this is always an array
    useAlert(t('CALL_MODAL.CONTACT_SEARCH_ERROR'));
  } finally {
    isSearching.value = false;
  }
}, 300);

const makeCall = async () => {
  if (!selectedInbox.value || !selectedContact.value) {
    useAlert(t('CALL_MODAL.VALIDATION_ERROR'));
    return;
  }

  isLoading.value = true;

  try {
    const isDirect = selectedContact.value.sourceId === 'direct-call';
    const contactId = isDirect ? null : (selectedContact.value.sourceId || selectedContact.value.id);
    
    if (contactId) {
      console.log('Making call to contact ID:', contactId, 'with full contact:', selectedContact.value);
      // Use VoiceAPI.initiateCall instead of direct axios call
      await VoiceAPI.initiateCall(contactId);
    } else {
      // For direct phone number calls
      const phoneNumber = selectedContact.value.phoneNumber;

      if (!phoneNumber) {
        throw new Error('Phone number is required for direct calls');
      }

      // First create a contact with this phone number
      console.log('Creating new contact with phone number:', phoneNumber);
      const contactPayload = {
        phone_number: phoneNumber,
        inbox_id: selectedInbox.value.sourceId,
        name: `Phone: ${phoneNumber}`,
      };

      const contactResponse = await ContactAPI.create(contactPayload);
      console.log('Created contact:', contactResponse.data);

      // Then initiate call to the newly created contact
      if (contactResponse.data && contactResponse.data.payload && contactResponse.data.payload.contact) {
        const newContactId = contactResponse.data.payload.contact.id;
        console.log('Using new contact ID:', newContactId);
        await VoiceAPI.initiateCall(newContactId);
      } else {
        throw new Error('Failed to create contact for direct call');
      }
    }

    useAlert(t('CALL_MODAL.SUCCESS_MESSAGE'));
    emit('close');
  } catch (error) {
    console.error('Error making call:', error);

    let errorMessage = t('CALL_MODAL.ERROR_MESSAGE');

    // Simple error handling - just show server message if available
    if (error.response && error.response.data && error.response.data.error) {
      errorMessage = error.response.data.error;
    }

    useAlert(errorMessage);
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  // The first inbox will be selected automatically via the watch
  // This ensures it works even if voiceInboxesList is populated after mounting
});
</script>