<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Modal from 'dashboard/components/Modal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ContactSelector from 'dashboard/components-next/NewConversation/components/ContactSelector.vue';
import InboxSelector from 'dashboard/components-next/NewConversation/components/InboxSelector.vue';
import {
  createContactSearcher,
  createNewContact,
  fetchContactableInboxes,
  mergeInboxDetails,
  buildContactableInboxesList,
} from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper.js';

const props = defineProps({
  selectedMessages: {
    type: Array,
    default: () => [],
  },
  conversationId: {
    type: [Number, String],
    required: true,
  },
});
const emit = defineEmits(['forwarded', 'close']);
const searchContacts = createContactSearcher();
import ConversationApi from 'dashboard/api/conversations';

const show = defineModel('show', { type: Boolean, default: false });

const { t } = useI18n();

const currentUser = useMapGetter('getCurrentUser');
const inboxesList = useMapGetter('inboxes/getInboxes');

const contacts = ref([]);
const selectedContact = ref(null);
const targetInbox = ref(null);
const isCreatingContact = ref(false);
const isFetchingInboxes = ref(false);
const isSearching = ref(false);
const showContactsDropdown = ref(false);
const showInboxesDropdown = ref(false);

const contactableInboxesList = computed(() => {
  const contactInboxes = selectedContact.value?.contactInboxes || [];
  const baseInboxes = buildContactableInboxesList(contactInboxes);

  const bsuid = selectedContact.value?.bsuid || '';
  const groupId = selectedContact.value?.email?.endsWith('@g.us')
    ? selectedContact.value.email
    : '';
  const contactPhone = selectedContact.value?.phoneNumber || bsuid || groupId;

  const unoFallbackInboxes = (() => {
    if (!contactPhone || (!bsuid && !groupId)) return [];

    return (
      inboxesList.value
        ?.filter(inbox => {
          const provider = inbox.provider || inbox.provider_name;
          const channelType = inbox.channel_type || inbox.channelType;
          return (
            channelType === 'Channel::Whatsapp' &&
            provider &&
            provider.toLowerCase() === 'unoapi'
          );
        })
        .map(inbox => ({
          id: inbox.id,
          name: inbox.name,
          email: inbox.email,
          phoneNumber: contactPhone,
          channelType: inbox.channel_type || inbox.channelType,
          medium: inbox.medium,
          sourceId: inbox.source_id || inbox.sourceId,
        })) || []
    );
  })();

  if (!unoFallbackInboxes.length) {
    return baseInboxes;
  }

  const unoContactable = buildContactableInboxesList(unoFallbackInboxes);
  const existingIds = new Set(baseInboxes.map(inbox => inbox.id));
  const merged = [
    ...unoContactable.filter(inbox => !existingIds.has(inbox.id)),
    ...baseInboxes,
  ];

  return merged;
});

const forwardMessagePreview = computed(() => {
  if (!props.selectedMessages || !props.selectedMessages.length) {
    return '';
  }

  const lines = props.selectedMessages
    .map(message => {
      const senderName = message.sender?.name || '';
      const content = message.content || '';
      if (!content) return '';
      if (senderName) {
        return `${senderName}: ${content}`;
      }
      return content;
    })
    .filter(Boolean);

  return lines.join('\n');
});

const hasForwardableContent = computed(() => {
  if (!props.selectedMessages || !props.selectedMessages.length) {
    return false;
  }

  const hasText = forwardMessagePreview.value.trim().length > 0;
  const hasAttachments = props.selectedMessages.some(message => {
    return Array.isArray(message.attachments) && message.attachments.length > 0;
  });

  return hasText || hasAttachments;
});

const resetState = () => {
  contacts.value = [];
  selectedContact.value = null;
  targetInbox.value = null;
  isCreatingContact.value = false;
  isFetchingInboxes.value = false;
  isSearching.value = false;
  showContactsDropdown.value = false;
  showInboxesDropdown.value = false;
};

const close = () => {
  resetState();
  emit('close');
};

const handleClose = () => {
  show.value = false;
  close();
};

const handleContactSearch = async value => {
  const query = typeof value === 'string' ? value.trim() : '';
  if (!query) {
    contacts.value = [];
    return;
  }

  isSearching.value = true;
  showContactsDropdown.value = true;
  contacts.value = [];
  try {
    contacts.value = await searchContacts(query);
  } catch (error) {
    useAlert(t('COMPOSE_NEW_CONVERSATION.CONTACT_SEARCH.ERROR_MESSAGE'));
  } finally {
    isSearching.value = false;
  }
};

const handleSelectedContact = async ({ value, action, ...rest }) => {
  let contact;
  if (action === 'create') {
    isCreatingContact.value = true;
    try {
      contact = await createNewContact(value);
    } catch (error) {
      isCreatingContact.value = false;
      return;
    }
    isCreatingContact.value = false;
  } else {
    contact = rest;
  }

  contact = {
    ...contact,
    phoneNumber: contact.phoneNumber || contact.bsuid,
  };

  selectedContact.value = contact;

  if (contact?.id) {
    isFetchingInboxes.value = true;
    try {
      const contactableInboxes = await fetchContactableInboxes(contact.id);
      selectedContact.value.contactInboxes = mergeInboxDetails(
        contactableInboxes,
        inboxesList.value
      );
    } catch (error) {
      // ignore
    } finally {
      isFetchingInboxes.value = false;
    }
  }
};

const handleTargetInbox = inbox => {
  targetInbox.value = inbox;
};

const clearSelectedContact = () => {
  selectedContact.value = null;
  targetInbox.value = null;
  contacts.value = [];
};

const canSubmit = computed(() => {
  return (
    !!selectedContact.value &&
    !!targetInbox.value &&
    hasForwardableContent.value &&
    !isFetchingInboxes.value
  );
});

const handleContactDropdownUpdate = type => {
  if (type === 'contacts') {
    showContactsDropdown.value = false;
  }
};

const handleInboxDropdownToggle = value => {
  showInboxesDropdown.value = value;
};

const handleForward = async () => {
  if (!canSubmit.value || !currentUser.value) {
    return;
  }

  if (!hasForwardableContent.value) {
    useAlert(t('CONVERSATION.FORWARD_MESSAGES.ERROR_NO_CONTENT'));
    return;
  }

  try {
    const { data } = await ConversationApi.forwardMessages(
      props.conversationId,
      {
        message_ids: props.selectedMessages.map(message => message.id),
        target_contact_id: selectedContact.value.id,
        target_inbox_id: targetInbox.value.id,
      }
    );
    emit('forwarded', data);
    show.value = false;
    resetState();
  } catch (error) {
    useAlert(t('CONVERSATION.FORWARD_MESSAGES.ERROR_API'));
  }
};
</script>

<template>
  <Modal v-model:show="show" :on-close="handleClose">
    <woot-modal-header
      :header-title="$t('CONVERSATION.FORWARD_MESSAGES.TITLE')"
      :header-content="$t('CONVERSATION.FORWARD_MESSAGES.DESCRIPTION')"
    />
    <div class="flex flex-col gap-4 p-8">
      <p class="text-xs text-n-slate-11">
        {{
          $t('CONVERSATION.FORWARD_MESSAGES.SELECTED_COUNT', {
            count: selectedMessages.length,
          })
        }}
      </p>

      <div class="flex flex-col gap-2">
        <ContactSelector
          :contacts="contacts"
          :selected-contact="selectedContact"
          :show-contacts-dropdown="showContactsDropdown"
          :is-loading="isSearching"
          :is-creating-contact="isCreatingContact"
          :contact-id="null"
          :contactable-inboxes-list="contactableInboxesList"
          :show-inboxes-dropdown="showInboxesDropdown"
          :has-errors="false"
          @search-contacts="handleContactSearch"
          @set-selected-contact="handleSelectedContact"
          @clear-selected-contact="clearSelectedContact"
          @update-dropdown="handleContactDropdownUpdate"
        />
        <InboxSelector
          :target-inbox="targetInbox"
          :selected-contact="selectedContact"
          :show-inboxes-dropdown="showInboxesDropdown"
          :contactable-inboxes-list="contactableInboxesList"
          :has-errors="false"
          @update-inbox="handleTargetInbox"
          @toggle-dropdown="handleInboxDropdownToggle"
          @handle-inbox-action="handleTargetInbox"
        />
      </div>

      <div
        class="rounded-md bg-n-alpha-2 p-3 text-xs text-n-slate-12 whitespace-pre-line"
      >
        {{ forwardMessagePreview }}
      </div>

      <div class="flex justify-end gap-2">
        <Button
          variant="ghost"
          color="slate"
          size="sm"
          :label="$t('CONVERSATION.FORWARD_MESSAGES.CANCEL')"
          type="button"
          @click="handleClose"
        />
        <Button
          color="blue"
          size="sm"
          :disabled="!canSubmit"
          :label="$t('CONVERSATION.FORWARD_MESSAGES.ACTION_LABEL')"
          type="button"
          @click="handleForward"
        />
      </div>
    </div>
  </Modal>
</template>
