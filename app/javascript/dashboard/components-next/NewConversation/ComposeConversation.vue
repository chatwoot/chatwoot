<script setup>
import { reactive, ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { useWindowSize } from '@vueuse/core';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useInboxSignatures } from 'dashboard/composables/useInboxSignatures';
import { vOnClickOutside } from '@vueuse/components';
import { useAlert } from 'dashboard/composables';
import { ExceptionWithMessage } from 'shared/helpers/CustomErrors';
import { debounce } from '@chatwoot/utils';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
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
import wootConstants from 'dashboard/constants/globals';

import ComposeNewConversationForm from 'dashboard/components-next/NewConversation/components/ComposeNewConversationForm.vue';
import ComposeNewGroupForm from 'dashboard/components-next/NewConversation/components/ComposeNewGroupForm.vue';

const props = defineProps({
  alignPosition: {
    type: String,
    default: 'left',
  },
  contactId: {
    type: String,
    default: null,
  },
  isModal: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close']);

const searchContacts = createContactSearcher();
const store = useStore();
const { t } = useI18n();
const router = useRouter();
const route = useRoute();
const { width: windowWidth } = useWindowSize();

const { fetchSignatureFlagFromUISettings } = useUISettings();

const isSmallScreen = computed(
  () => windowWidth.value < wootConstants.SMALL_SCREEN_BREAKPOINT
);

const viewInModal = computed(() => props.isModal || isSmallScreen.value);

const contacts = ref([]);
const selectedContact = ref(null);
const targetInbox = ref(null);
const isCreatingContact = ref(false);
const isFetchingInboxes = ref(false);
const isSearching = ref(false);
const showComposeNewConversation = ref(false);
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

const resetContacts = () => {
  contacts.value = [];
};

const closeCompose = () => {
  showComposeNewConversation.value = false;
  composeMode.value = 'conversation';
  if (!props.contactId) {
    selectedContact.value = null;
  }
  targetInbox.value = null;
  resetContacts();
  groupFormRef.value?.resetForm();
  emit('close');
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

const composePopoverClass = computed(() => {
  if (viewInModal.value) return '';

  return props.alignPosition === 'right'
    ? 'absolute ltr:left-0 ltr:right-[unset] rtl:right-0 rtl:left-[unset]'
    : 'absolute rtl:left-0 rtl:right-[unset] ltr:right-0 ltr:left-[unset]';
});

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

const toggle = () => {
  showComposeNewConversation.value = !showComposeNewConversation.value;
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

const handleClickOutside = () => {
  if (!showComposeNewConversation.value) return;

  showComposeNewConversation.value = false;
  emit('close');
};

const onModalBackdropClick = () => {
  if (!viewInModal.value) return;
  handleClickOutside();
};

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

const keyboardEvents = {
  Escape: {
    action: () => {
      if (showComposeNewConversation.value) {
        showComposeNewConversation.value = false;
        emit('close');
        emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, false);
      }
    },
  },
};

useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div
    v-on-click-outside="[
      handleClickOutside,
      // Fixed and edge case https://github.com/chatwoot/chatwoot/issues/10785
      // This will prevent closing the compose conversation modal when the editor Create link popup is open
      { ignore: ['dialog.ProseMirror-prompt-backdrop'] },
    ]"
    class="relative"
    :class="{
      'z-50': showComposeNewConversation && !viewInModal,
    }"
  >
    <slot
      name="trigger"
      :is-open="showComposeNewConversation"
      :toggle="toggle"
    />
    <div
      v-if="showComposeNewConversation"
      :class="{
        'fixed z-50 bg-n-alpha-black1 backdrop-blur-[4px] flex items-start pt-[clamp(3rem,15vh,12rem)] justify-center inset-0':
          viewInModal,
      }"
      @click.self="onModalBackdropClick"
    >
      <div
        v-if="!isGroupMode"
        :class="[{ 'mt-2': !viewInModal }, composePopoverClass]"
        class="w-[42rem] flex flex-col"
      >
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
      </div>

      <div
        v-else
        :class="[{ 'mt-2': !viewInModal }, composePopoverClass]"
        class="w-[42rem] flex flex-col"
      >
        <div
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
        <ComposeNewGroupForm
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
    </div>
  </div>
</template>
