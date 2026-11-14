<script setup>
import { reactive, ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useInboxSignatures } from 'dashboard/composables/useInboxSignatures';
import { useAlert } from 'dashboard/composables';
import {
  CONTACT_FIELD_LABELS,
  requestErrorMessage,
} from 'dashboard/helper/requestErrorMessage';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import { debounce } from '@chatwoot/utils';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  createContactSearcher,
  createNewContact,
  fetchContactableInboxes,
  processContactableInboxes,
  mergeInboxDetails,
} from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import { pendingGroupNavigation } from 'dashboard/helper/pendingGroupNavigation';

import Popover from 'dashboard/components-next/popover/Popover.vue';
import ComposeNewConversationForm from 'dashboard/components-next/NewConversation/components/ComposeNewConversationForm.vue';
import ComposeNewGroupForm from 'dashboard/components-next/NewConversation/components/ComposeNewGroupForm.vue';

const props = defineProps({
  contactId: {
    type: String,
    default: null,
  },
  align: {
    type: String,
    default: 'end',
  },
});

const emit = defineEmits(['close']);

const searchContacts = createContactSearcher();
const store = useStore();
const { t } = useI18n();
const router = useRouter();
const route = useRoute();

const { fetchSignatureFlagFromUISettings } = useUISettings();

const popoverRef = ref(null);
const contacts = ref([]);
const selectedContact = ref(null);
const targetInbox = ref(null);
const isCreatingContact = ref(false);
const isFetchingInboxes = ref(false);
const isSearching = ref(false);
const composeMode = ref('conversation');
const groupFormRef = ref(null);

const formState = reactive({
  message: '',
  subject: '',
  ccEmails: '',
  bccEmails: '',
  attachedFiles: [],
});

const clearFormState = () => {
  Object.assign(formState, {
    subject: '',
    ccEmails: '',
    bccEmails: '',
    attachedFiles: [],
  });
};

const contactById = useMapGetter('contacts/getContactById');
const contactsUiFlags = useMapGetter('contacts/getUIFlags');
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');
const uiFlags = useMapGetter('contactConversations/getUIFlags');
const messageSignature = useMapGetter('getMessageSignature');
const inboxesList = useMapGetter('inboxes/getInboxes');
const groupUiFlags = useMapGetter('groupMembers/getUIFlags');

const groupCreationInboxes = computed(() =>
  inboxesList.value.filter(inbox => inbox.allow_group_creation)
);

const isGroupMode = computed(() => composeMode.value === 'group');
const hasGroupInboxes = computed(() => groupCreationInboxes.value.length > 0);
const isGroupsDisabled = computed(
  () => !globalConfig.value.baileysWhatsappGroupsEnabled
);
const isSuperAdmin = computed(() => currentUser.value.type === 'SuperAdmin');

const {
  fetchInboxSignatures,
  getSignatureForInbox,
  getSignatureSettingsForInbox,
} = useInboxSignatures();

fetchInboxSignatures();

const resolvedMessageSignature = computed(() => {
  if (!targetInbox.value?.id) return messageSignature.value;
  return getSignatureForInbox(targetInbox.value.id);
});

const resolvedSignatureSettings = computed(() => {
  if (!targetInbox.value?.id) return null;
  return getSignatureSettingsForInbox(targetInbox.value.id);
});

const sendWithSignature = computed(() =>
  fetchSignatureFlagFromUISettings(targetInbox.value?.channelType)
);

const directUploadsEnabled = computed(
  () => globalConfig.value.directUploadsEnabled
);

const activeContact = computed(() => contactById.value(props.contactId));

const resetContacts = () => {
  contacts.value = [];
};

const onContactSearch = debounce(
  async query => {
    isSearching.value = true;
    contacts.value = [];
    try {
      const results = await searchContacts(query);
      // null means the request was aborted (a newer search is in-flight),
      if (results === null) return;
      contacts.value = results;
      isSearching.value = false;
    } catch (error) {
      isSearching.value = false;
      useAlert(t('COMPOSE_NEW_CONVERSATION.CONTACT_SEARCH.ERROR_MESSAGE'));
    }
  },
  400,
  false
);

const handleSelectedContact = async ({ value, action, ...rest }) => {
  let contact;
  if (action === 'create') {
    isCreatingContact.value = true;
    try {
      contact = await createNewContact(value);
      isCreatingContact.value = false;
    } catch (error) {
      isCreatingContact.value = false;
      useAlert(
        requestErrorMessage(
          error,
          t,
          'COMPOSE_NEW_CONVERSATION.CONTACT_CREATE.ERROR_MESSAGE',
          CONTACT_FIELD_LABELS
        )
      );
      return;
    }
  } else {
    contact = rest;
  }
  selectedContact.value = contact;
  contacts.value = [];
  if (contact?.id) {
    isFetchingInboxes.value = true;
    try {
      const contactableInboxes = await fetchContactableInboxes(contact.id);
      // Merge the processed contactableInboxes with the inboxesList
      selectedContact.value.contactInboxes = mergeInboxDetails(
        contactableInboxes,
        inboxesList.value
      );

      isFetchingInboxes.value = false;
    } catch (error) {
      isFetchingInboxes.value = false;
    }
  }
};

const handleTargetInbox = inbox => {
  targetInbox.value = inbox;
  if (!inbox) clearFormState();
  resetContacts();
};

const clearSelectedContact = () => {
  selectedContact.value = null;
  targetInbox.value = null;
  clearFormState();
};

const closeCompose = () => {
  popoverRef.value?.hide();
};

const discardCompose = () => {
  clearFormState();
  formState.message = '';
  closeCompose();
};

const switchMode = mode => {
  if (composeMode.value === mode) return;
  composeMode.value = mode;
  selectedContact.value = null;
  targetInbox.value = null;
  clearFormState();
  formState.message = '';
  resetContacts();
  groupFormRef.value?.resetForm();
};

const createGroup = async ({ inboxId, subject, participants }) => {
  try {
    const data = await store.dispatch('groupMembers/createGroup', {
      inbox_id: inboxId,
      subject,
      participants,
    });
    pendingGroupNavigation.set(data.group_jid);
    groupFormRef.value?.resetForm();
    discardCompose();
    useAlert(t('GROUP.CREATE.SUCCESS_MESSAGE'));
  } catch {
    useAlert(t('GROUP.CREATE.ERROR_MESSAGE'));
  }
};

// The conversation carries the first attachment; anything else the agent picked follows
// it as its own message. Only channels that cannot carry more than one per message get
// here with a non-empty list — see splitAttachmentsForChannel.
// Chained rather than fired together, so the attachments arrive in the order they were
// picked: WhatsApp orders by arrival, and a Promise.all reorders them for the contact.
const sendFollowUpFiles = (conversationId, followUpFiles) =>
  followUpFiles.reduce(
    (previous, file) =>
      previous.then(() =>
        store.dispatch('createPendingMessageAndSend', {
          conversationId,
          files: [
            directUploadsEnabled.value ? file.blobSignedId : file.resource.file,
          ],
          message: '',
          private: false,
        })
      ),
    Promise.resolve()
  );

const createConversation = async ({
  payload,
  followUpFiles = [],
  isFromWhatsApp,
}) => {
  try {
    const data = await store.dispatch('contactConversations/create', {
      params: payload,
      isFromWhatsApp,
    });
    if (followUpFiles.length) await sendFollowUpFiles(data.id, followUpFiles);
    const action = {
      type: 'link',
      to: `/app/accounts/${data.account_id}/conversations/${data.id}`,
      message: t('COMPOSE_NEW_CONVERSATION.FORM.GO_TO_CONVERSATION'),
    };
    discardCompose();
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

const onPopoverShow = () => {
  // Flag to prevent triggering drag n drop while compose is open
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, true);
  // Cache-aware refetch, so newly synced WhatsApp templates show up here
  // even if the account-cache-invalidated websocket event was missed.
  store.dispatch('inboxes/get');
};

const onPopoverHide = () => {
  composeMode.value = 'conversation';
  if (!props.contactId) {
    selectedContact.value = null;
  }
  targetInbox.value = null;
  resetContacts();
  groupFormRef.value?.resetForm();
  emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, false);
  emit('close');
};

watch(
  activeContact,
  (currentContact, previousContact) => {
    if (currentContact && props.contactId) {
      // Reset on contact change
      if (currentContact?.id !== previousContact?.id) {
        clearSelectedContact();
        clearFormState();
        formState.message = '';
      }

      // First process the contactable inboxes to get the right structure
      const processedInboxes = processContactableInboxes(
        currentContact.contactInboxes || []
      );
      // Then Merge processedInboxes with the inboxes list
      selectedContact.value = {
        ...currentContact,
        contactInboxes: mergeInboxDetails(processedInboxes, inboxesList.value),
      };
    }
  },
  { immediate: true, deep: true }
);

const navigateToGroup = ({ conversationId }) => {
  const url = frontendURL(
    conversationUrl({
      accountId: route.params.accountId,
      id: conversationId,
    })
  );
  router.push({ path: url });
};

onMounted(() => {
  resetContacts();
  emitter.on(BUS_EVENTS.NAVIGATE_TO_GROUP, navigateToGroup);
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.NAVIGATE_TO_GROUP, navigateToGroup);
});
</script>

<template>
  <Popover
    ref="popoverRef"
    :align="align"
    :show-content-border="false"
    :close-on-scroll="false"
    @show="onPopoverShow"
    @hide="onPopoverHide"
  >
    <template #default="{ isOpen }">
      <slot name="trigger" :is-open="isOpen" />
    </template>
    <template #content>
      <div class="w-full md:w-[42rem] flex flex-col min-w-0">
        <div
          v-if="hasGroupInboxes"
          class="flex gap-1 px-4 pt-3 pb-0 bg-n-alpha-3 border border-b-0 border-n-strong backdrop-blur-[100px] rounded-t-xl"
        >
          <button
            class="px-3 py-1.5 text-sm font-medium rounded-t-lg border-b-2 transition-colors"
            :class="
              !isGroupMode
                ? 'text-n-brand border-n-brand bg-n-alpha-2'
                : 'text-n-slate-11 border-transparent hover:text-n-slate-12'
            "
            @click="switchMode('conversation')"
          >
            {{ t('COMPOSE_NEW_CONVERSATION.TAB_CONVERSATION') }}
          </button>
          <button
            class="px-3 py-1.5 text-sm font-medium rounded-t-lg border-b-2 transition-colors"
            :class="
              isGroupMode
                ? 'text-n-brand border-n-brand bg-n-alpha-2'
                : 'text-n-slate-11 border-transparent hover:text-n-slate-12'
            "
            @click="switchMode('group')"
          >
            {{ t('COMPOSE_NEW_CONVERSATION.TAB_GROUP') }}
          </button>
        </div>
        <ComposeNewConversationForm
          v-if="!isGroupMode"
          :form-state="formState"
          :class="{ '!rounded-t-none !border-t-0': hasGroupInboxes }"
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
          :message-signature="resolvedMessageSignature"
          :send-with-signature="sendWithSignature"
          :signature-settings="resolvedSignatureSettings"
          @search-contacts="onContactSearch"
          @reset-contact-search="resetContacts"
          @update-selected-contact="handleSelectedContact"
          @update-target-inbox="handleTargetInbox"
          @clear-selected-contact="clearSelectedContact"
          @create-conversation="createConversation"
          @discard="discardCompose"
        />
        <ComposeNewGroupForm
          v-else
          ref="groupFormRef"
          class="!rounded-t-none !border-t-0"
          :inboxes="groupCreationInboxes"
          :is-creating="groupUiFlags.isCreating"
          :is-groups-disabled="isGroupsDisabled"
          :is-super-admin="isSuperAdmin"
          @create-group="createGroup"
          @discard="discardCompose"
        />
      </div>
    </template>
  </Popover>
</template>
