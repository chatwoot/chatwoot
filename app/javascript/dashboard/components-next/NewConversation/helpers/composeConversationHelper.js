import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import camelcaseKeys from 'camelcase-keys';
import ContactAPI from 'dashboard/api/contacts';

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
  return name;
};

export const buildContactableInboxesList = contactInboxes => {
  if (!contactInboxes) return [];
  return contactInboxes.map(
    ({ name, id, email, channelType, phoneNumber, ...rest }) => ({
      id,
      icon: getInboxIconByType(channelType, phoneNumber, 'line'),
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

export const generateContactQuery = ({ keys = ['email'], query }) => {
  return {
    payload: keys.map(key => {
      const filterPayload = {
        attribute_key: key,
        filter_operator: 'contains',
        values: [query],
        attribute_model: 'standard',
      };
      if (keys.findIndex(k => k === key) !== keys.length - 1) {
        filterPayload.query_operator = 'or';
      }
      return filterPayload;
    }),
  };
};

// API Calls
export const searchContacts = async ({ keys, query }) => {
  const {
    data: { payload },
  } = await ContactAPI.filter(
    undefined,
    'name',
    generateContactQuery({ keys, query })
  );
  const camelCasedPayload = camelcaseKeys(payload, { deep: true });
  // Filter contacts that have either phone_number or email
  const filteredPayload = camelCasedPayload?.filter(
    contact => contact.phoneNumber || contact.email
  );
  return filteredPayload || [];
};

export const createNewContact = async email => {
  const payload = {
    name: getCapitalizedNameFromEmail(email),
    email,
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
