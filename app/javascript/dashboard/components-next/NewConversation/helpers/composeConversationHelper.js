import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { appendSignature } from 'dashboard/helper/editorHelper';
import { DEFAULT_SIGNATURE_SEPARATOR } from 'dashboard/constants/signatureSeparators';
import camelcaseKeys from 'camelcase-keys';
import ContactAPI from 'dashboard/api/contacts';

const CHANNEL_PRIORITY = {
  'Channel::Email': 1,
  'Channel::Whatsapp': 2,
  'Channel::Sms': 3,
  'Channel::TwilioSms': 4,
  'Channel::WebWidget': 5,
  'Channel::Api': 6,
};

export const generateLabelForContactableInboxesList = ({
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
    return phoneNumber ? `${name} (${phoneNumber})` : name;
  }
  return name;
};

const transformInbox = ({
  name,
  id,
  email,
  channelType,
  phoneNumber,
  medium,
  voiceEnabled,
  ...rest
}) => ({
  id,
  icon: getInboxIconByType(channelType, medium, 'line', voiceEnabled),
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
  medium,
  voiceEnabled,
  ...rest,
});

export const compareInboxes = (a, b) => {
  // Channels that have no priority defined should come at the end.
  const priorityA = CHANNEL_PRIORITY[a.channelType] || 999;
  const priorityB = CHANNEL_PRIORITY[b.channelType] || 999;

  if (priorityA !== priorityB) {
    return priorityA - priorityB;
  }

  const nameA = a.name || '';
  const nameB = b.name || '';
  return nameA.localeCompare(nameB);
};

export const buildContactableInboxesList = contactInboxes => {
  if (!contactInboxes) return [];

  return contactInboxes.map(transformInbox).sort(compareInboxes);
};

export const getCapitalizedNameFromEmail = email => {
  const name = email.match(/^([^@]*)@/)?.[1] || email.split('@')[0];
  return name.charAt(0).toUpperCase() + name.slice(1);
};

export const processContactableInboxes = inboxes => {
  return inboxes.map(inbox => ({
    ...inbox.inbox,
    sourceId: inbox.sourceId,
  }));
};

export const mergeInboxDetails = (inboxesData, inboxesList = []) => {
  if (!inboxesData || !inboxesData.length) {
    return [];
  }

  return inboxesData.map(inboxData => {
    const matchingInbox =
      inboxesList.find(inbox => inbox.id === inboxData.id) || {};
    return {
      ...camelcaseKeys(matchingInbox, { deep: true }),
      ...inboxData,
    };
  });
};

export const prepareAttachmentPayload = (
  attachedFiles,
  directUploadsEnabled
) => {
  const files = [];
  attachedFiles.forEach(attachment => {
    if (directUploadsEnabled) {
      files.push(attachment.blobSignedId);
    } else {
      files.push(attachment.resource.file);
    }
  });
  return files;
};

export const prepareNewMessagePayload = ({
  targetInbox,
  selectedContact,
  message,
  subject,
  ccEmails,
  bccEmails,
  currentUser,
  attachedFiles = [],
  directUploadsEnabled = false,
  sendWithSignature = false,
  messageSignature = '',
  signatureSettings = null,
}) => {
  let finalMessage = message;
  if (sendWithSignature && messageSignature) {
    const settings = signatureSettings || {
      position: currentUser?.ui_settings?.signature_position || 'top',
      separator:
        currentUser?.ui_settings?.signature_separator ||
        DEFAULT_SIGNATURE_SEPARATOR,
    };
    finalMessage = appendSignature(message, messageSignature, settings);
  }

  const payload = {
    inboxId: targetInbox.id,
    sourceId: targetInbox.sourceId,
    contactId: Number(selectedContact.id),
    message: { content: finalMessage },
    assigneeId: currentUser.id,
  };

  if (attachedFiles?.length) {
    payload.files = prepareAttachmentPayload(
      attachedFiles,
      directUploadsEnabled
    );
  }

  if (subject) {
    payload.mailSubject = subject;
  }

  if (ccEmails) {
    payload.message.cc_emails = ccEmails;
  }

  if (bccEmails) {
    payload.message.bcc_emails = bccEmails;
  }

  return payload;
};

/**
 * Whether this inbox's channel carries one attachment per message.
 *
 * WhatsApp has no multi-media message, so every sender takes `attachments.first`
 * (`WhatsappBaileysService#attachment_message_content` and
 * `Whatsapp::Session::Outbound::MessageSender#attachment_content` alike). A payload with
 * three files therefore shows three in Chatwoot and delivers one, with nothing telling
 * the agent. The reply box already splits for this reason (#277).
 *
 * @param {{channelType?: string}|null|undefined} targetInbox
 * @returns {boolean}
 */
export const carriesOneAttachmentPerMessage = targetInbox =>
  targetInbox?.channelType === INBOX_TYPES.WHATSAPP;

/**
 * Splits the attached files into the one that travels with the new conversation and the
 * ones that have to follow it as their own messages.
 *
 * Only for the channels that need it: on email and the web widget one message carrying
 * several files is correct, and splitting there would turn one email into three.
 *
 * @param {{targetInbox: Object, attachedFiles: Array}} params
 * @returns {{first: Array, rest: Array}}
 */
export const splitAttachmentsForChannel = ({
  targetInbox,
  attachedFiles = [],
}) => {
  if (
    !carriesOneAttachmentPerMessage(targetInbox) ||
    attachedFiles.length < 2
  ) {
    return { first: attachedFiles, rest: [] };
  }
  return { first: attachedFiles.slice(0, 1), rest: attachedFiles.slice(1) };
};

export const prepareWhatsAppMessagePayload = ({
  targetInbox,
  selectedContact,
  message,
  templateParams,
  currentUser,
}) => {
  return {
    inboxId: targetInbox.id,
    sourceId: targetInbox.sourceId,
    contactId: selectedContact.id,
    message: { content: message, template_params: templateParams },
    assigneeId: currentUser.id,
  };
};

// API Calls
const MIN_SEARCH_LENGTH = 2;

export const createContactSearcher = () => {
  let controller = null;

  return async (
    query,
    { skipMinLength = false, reachableOnly = true } = {}
  ) => {
    const trimmed = typeof query === 'string' ? query.trim() : '';

    controller?.abort();

    if (!trimmed || (!skipMinLength && trimmed.length < MIN_SEARCH_LENGTH))
      return [];

    controller = new AbortController();
    const { signal } = controller;

    try {
      const {
        data: { payload },
      } = await ContactAPI.search(trimmed, 1, 'name', '', { signal });

      const camelCasedPayload = camelcaseKeys(payload, { deep: true });
      if (!reachableOnly) return camelCasedPayload || [];

      // Filter contacts that have either phone_number or email
      const filteredPayload = camelCasedPayload?.filter(
        contact => contact.phoneNumber || contact.email
      );
      return filteredPayload || [];
    } catch (error) {
      // Return null for aborted requests so callers can distinguish
      // "request was cancelled" from "no results found"
      if (error?.name === 'AbortError' || error?.name === 'CanceledError') {
        return null;
      }
      throw error;
    }
  };
};

export const createNewContact = async input => {
  const payload = {
    name: input.startsWith('+')
      ? input.slice(1) // Remove the '+' prefix if it exists
      : getCapitalizedNameFromEmail(input),
    ...(input.startsWith('+') ? { phone_number: input } : { email: input }),
  };

  const {
    data: {
      payload: { contact: newContact },
    },
  } = await ContactAPI.create(payload);

  return camelcaseKeys(newContact, { deep: true });
};

export const fetchContactableInboxes = async contactId => {
  const {
    data: { payload: inboxes = [] },
  } = await ContactAPI.getContactableInboxes(contactId);

  const convertInboxesToCamelKeys = camelcaseKeys(inboxes, { deep: true });

  return processContactableInboxes(convertInboxesToCamelKeys);
};
