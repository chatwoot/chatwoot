<script setup>
import { computed, reactive, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { parseISO, isValid } from 'date-fns';
import { vOnClickOutside } from '@vueuse/components';
import { debounce, getFileInfo } from '@chatwoot/utils';
import { useAlert } from 'dashboard/composables';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  appendSignature,
  removeSignature,
} from 'dashboard/helper/editorHelper';
import { formatQuotedEmailDate } from 'dashboard/helper/quotedEmailHelper';
import {
  buildForwardedEmailHtml,
  textToHtml,
} from 'dashboard/helper/forwardEmailHelper';
import { createContactSearcher } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';
import MessageFormatter from 'shared/helpers/MessageFormatter';

import ContextMenu from 'dashboard/components/ui/ContextMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import InboxSelector from 'dashboard/components-next/NewConversation/components/InboxSelector.vue';
import RecipientsInput from 'dashboard/components-next/NewConversation/components/RecipientsInput.vue';
import MessageEditor from 'dashboard/components-next/NewConversation/components/MessageEditor.vue';
import AttachmentPreviews from 'dashboard/components-next/NewConversation/components/AttachmentPreviews.vue';
import ActionButtons from 'dashboard/components-next/NewConversation/components/ActionButtons.vue';
import EditableEmailBody from './EditableEmailBody.vue';
import { useMessageContext } from '../provider.js';
import { MESSAGE_TYPES } from '../constants';

defineProps({
  x: { type: Number, default: 0 },
  y: { type: Number, default: 0 },
});

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();
const { fetchSignatureFlagFromUISettings } = useUISettings();
const {
  id: messageId,
  content,
  contentAttributes,
  attachments,
  messageType,
  sender,
  createdAt,
  conversationId,
  inboxId,
} = useMessageContext();

const currentChat = useMapGetter('getSelectedChat');
const currentUser = useMapGetter('getCurrentUser');
const globalConfig = useMapGetter('globalConfig/get');
const messageSignature = useMapGetter('getMessageSignature');
const inboxGetter = useMapGetter('inboxes/getInbox');

const inbox = computed(() => useCamelCase(inboxGetter.value(inboxId.value)));
const contact = computed(() => currentChat.value?.meta?.sender ?? {});
const sendWithSignature = computed(() =>
  fetchSignatureFlagFromUISettings(INBOX_TYPES.EMAIL)
);

const attachmentName = ({ dataUrl }) => {
  const { base, type } = getFileInfo(dataUrl);
  return type ? `${base}.${type}` : base;
};

const state = reactive({
  toEmails: [],
  ccEmails: [],
  bccEmails: [],
  message: '',
  attachedFiles: attachments.value.map(attachment => ({
    forwardedAttachmentId: attachment.id,
    thumb: attachment.thumbUrl,
    resource: {
      id: `forwarded-${attachment.id}`,
      name: attachmentName(attachment),
      type: attachment.fileType,
    },
  })),
});

const emailMeta = contentAttributes.value?.email ?? {};
const emailDate = parseISO(emailMeta.date ?? '');
const recipients = emailMeta.to ?? contentAttributes.value?.toEmails ?? [];
const forwardedHtml = buildForwardedEmailHtml({
  labels: {
    title: t('FORWARD_EMAIL.HEADER_TITLE'),
    from: t('EMAIL_HEADER.FROM'),
    date: t('EMAIL_HEADER.DATE'),
    subject: t('EMAIL_HEADER.SUBJECT'),
    to: t('EMAIL_HEADER.TO'),
  },
  sender:
    messageType.value === MESSAGE_TYPES.OUTGOING
      ? { name: inbox.value.name, email: inbox.value.email }
      : {
          name: sender.value?.name,
          email: emailMeta.from?.[0] ?? sender.value?.email,
        },
  date: formatQuotedEmailDate(
    isValid(emailDate) ? emailDate : new Date(createdAt.value * 1000)
  ),
  subject:
    emailMeta.subject ||
    currentChat.value?.additional_attributes?.mail_subject ||
    '',
  recipients: recipients.length
    ? recipients
    : [contact.value.email].filter(Boolean),
  bodyHtml:
    emailMeta.htmlContent?.full ||
    textToHtml(emailMeta.textContent?.full || content.value || ''),
});

const bodyRef = useTemplateRef('bodyRef');

useKeyboardEvents({ '$mod+z': () => bodyRef.value.undo() });

const searchContacts = createContactSearcher();
const contacts = ref([]);
const isSearching = ref(false);
const showBcc = ref(false);
const activeRecipientField = ref(null);

const closeRecipientDropdown = field => {
  if (activeRecipientField.value === field) activeRecipientField.value = null;
};

const onSearchContacts = debounce(
  async (field, query) => {
    activeRecipientField.value = query.trim().length >= 2 ? field : null;
    if (!activeRecipientField.value) return;

    isSearching.value = true;
    try {
      const results = await searchContacts(query);
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

const onAddSignature = signature => {
  state.message = appendSignature(state.message, signature, INBOX_TYPES.EMAIL);
};

const onRemoveSignature = signature => {
  state.message = removeSignature(state.message, signature, INBOX_TYPES.EMAIL);
};

const canSend = computed(() => state.toEmails.length > 0);

const forwardEmail = () => {
  if (!canSend.value) return;

  const body = bodyRef.value.getContent();
  const noteHtml = new MessageFormatter(state.message).formattedMessage;
  const forwardedFiles = state.attachedFiles.filter(
    file => file.forwardedAttachmentId
  );
  const uploadedFiles = state.attachedFiles.filter(
    file => !file.forwardedAttachmentId
  );

  store.dispatch('createPendingMessageAndSend', {
    conversationId: conversationId.value,
    message: [state.message, body.text].filter(Boolean).join('\n\n'),
    emailHtmlContent: `${noteHtml}${body.html}`,
    toEmails: state.toEmails.join(','),
    ccEmails: state.ccEmails.join(','),
    bccEmails: state.bccEmails.join(','),
    private: false,
    contentAttributes: { forwarded_message_id: messageId.value },
    forwardedAttachmentIds: forwardedFiles.map(
      file => file.forwardedAttachmentId
    ),
    files: uploadedFiles.map(file =>
      globalConfig.value.directUploadsEnabled
        ? file.blobSignedId
        : file.resource.file
    ),
    sender: {
      name: currentUser.value.name,
      thumbnail: currentUser.value.avatar_url,
    },
  });
  emit('close');
};
</script>

<template>
  <ContextMenu :x="x" :y="y" :close-on-focus-out="false" @close="emit('close')">
    <div
      v-on-click-outside="[
        () => emit('close'),
        {
          ignore: ['.ProseMirror-prompt', 'dialog.ProseMirror-prompt-backdrop'],
        },
      ]"
      class="w-full md:w-[42rem] divide-y divide-n-strong overflow-visible transition-all duration-300 ease-in-out top-full flex flex-col bg-n-alpha-3 border border-n-strong shadow-sm backdrop-blur-[100px] rounded-xl min-w-0 max-h-[calc(100vh-8rem)] cursor-default"
    >
      <div class="flex-1 overflow-y-auto divide-y divide-n-strong">
        <InboxSelector
          :target-inbox="inbox"
          :show-inboxes-dropdown="false"
          :removable="false"
        />
        <RecipientsInput
          v-model="state.toEmails"
          :label="t('FORWARD_EMAIL.TO_LABEL')"
          :placeholder="t('FORWARD_EMAIL.TO_PLACEHOLDER')"
          :contacts="contacts"
          :show-dropdown="activeRecipientField === 'to'"
          :is-loading="isSearching"
          @input="onSearchContacts('to', $event)"
          @on-click-outside="closeRecipientDropdown('to')"
        />
        <RecipientsInput
          v-model="state.ccEmails"
          :label="t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.CC_LABEL')"
          :placeholder="
            t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.CC_PLACEHOLDER')
          "
          :contacts="contacts"
          :show-dropdown="activeRecipientField === 'cc'"
          :is-loading="isSearching"
          @input="onSearchContacts('cc', $event)"
          @on-click-outside="closeRecipientDropdown('cc')"
        >
          <Button
            :label="t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.BCC_BUTTON')"
            variant="ghost"
            size="sm"
            color="slate"
            class="flex-shrink-0"
            @click="showBcc = !showBcc"
          />
        </RecipientsInput>
        <RecipientsInput
          v-if="showBcc"
          v-model="state.bccEmails"
          :label="t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.BCC_LABEL')"
          :placeholder="
            t('COMPOSE_NEW_CONVERSATION.FORM.EMAIL_OPTIONS.BCC_PLACEHOLDER')
          "
          :contacts="contacts"
          :show-dropdown="activeRecipientField === 'bcc'"
          :is-loading="isSearching"
          focus-on-mount
          @input="onSearchContacts('bcc', $event)"
          @on-click-outside="closeRecipientDropdown('bcc')"
        />
        <div>
          <MessageEditor
            v-model="state.message"
            :placeholder="t('FORWARD_EMAIL.MESSAGE_PLACEHOLDER')"
            compact
            :message-signature="messageSignature"
            :send-with-signature="sendWithSignature"
            :channel-type="INBOX_TYPES.EMAIL"
          />
          <EditableEmailBody
            ref="bodyRef"
            :html="forwardedHtml"
            class="px-4 pb-4"
          />
        </div>
        <AttachmentPreviews
          v-if="state.attachedFiles.length"
          :attachments="state.attachedFiles"
          @update:attachments="state.attachedFiles = $event"
        />
      </div>
      <ActionButtons
        :attached-files="state.attachedFiles"
        is-email-or-web-widget-inbox
        has-selected-inbox
        :channel-type="INBOX_TYPES.EMAIL"
        :inbox-id="inboxId"
        :disable-send-button="!canSend"
        :is-dropdown-active="activeRecipientField !== null"
        :message-signature="messageSignature"
        @insert-emoji="state.message += $event"
        @add-signature="onAddSignature"
        @remove-signature="onRemoveSignature"
        @attach-file="state.attachedFiles = $event"
        @discard="emit('close')"
        @send-message="forwardEmail"
      />
    </div>
  </ContextMenu>
</template>
