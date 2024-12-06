import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const convertChannelTypeToLabel = channelType => {
  const [, type] = channelType.split('::');
  return type ? type.charAt(0).toUpperCase() + type.slice(1) : channelType;
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
    return `${name} (${phoneNumber})`;
  }
  return `${name} (${convertChannelTypeToLabel(channelType)})`;
};

export const buildContactableInboxesList = contactInboxes => {
  if (!contactInboxes) return [];
  return contactInboxes.map(
    ({ name, id, email, channelType, phoneNumber, ...rest }) => ({
      id,
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
      ...rest,
    })
  );
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
}) => {
  const payload = {
    inboxId: targetInbox.id,
    sourceId: targetInbox.sourceId,
    contactId: Number(selectedContact.id),
    message: { content: message },
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
