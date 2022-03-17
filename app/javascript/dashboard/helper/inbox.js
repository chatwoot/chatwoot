import { INBOX_TYPES } from 'shared/mixins/inboxMixin';
import { isEmptyObject } from 'dashboard/helper/commons';

export const getInboxClassByType = (type, phoneNumber) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'globe-desktop';

    case INBOX_TYPES.FB:
      return 'brand-facebook';

    case INBOX_TYPES.TWITTER:
      return 'brand-twitter';

    case INBOX_TYPES.TWILIO:
      return phoneNumber.startsWith('whatsapp')
        ? 'brand-whatsapp'
        : 'brand-sms';

    case INBOX_TYPES.WHATSAPP:
      return 'brand-whatsapp';

    case INBOX_TYPES.API:
      return 'cloud';

    case INBOX_TYPES.EMAIL:
      return 'mail';

    case INBOX_TYPES.TELEGRAM:
      return 'brand-telegram';

    case INBOX_TYPES.LINE:
      return 'brand-line';

    default:
      return 'chat';
  }
};

export const getCustomFields = ({ standardFields, customAttributes }) => {
  let customFields = [];
  const { pre_chat_fields: preChatFields } = standardFields;
  customAttributes.forEach(attribute => {
    const itemExist = preChatFields.find(
      item => item.name === attribute.attribute_key
    );
    if (!itemExist) {
      customFields.push({
        label: attribute.attribute_display_name,
        name: attribute.attribute_key,
        type: attribute.attribute_display_type,
        values: attribute.attribute_values,
        field_type: 'custom',
        required: false,
        enabled: false,
      });
    }
  });
  return customFields;
};

export const getStandardFields = ({
  requireEmail,
  emailEnabled,
  preChatMessage,
}) => {
  return {
    pre_chat_message: preChatMessage || 'Share your queries or comments here.',
    pre_chat_fields: [
      {
        label: 'Email Id',
        name: 'emailAddress',
        type: 'email',
        field_type: 'standard',
        required: requireEmail || false,
        enabled: emailEnabled || false,
      },
      {
        label: 'Full name',
        name: 'fullName',
        type: 'text',
        field_type: 'standard',
        required: false,
        enabled: false,
      },
      {
        label: 'Phone number',
        name: 'phoneNumber',
        type: 'text',
        field_type: 'standard',
        required: false,
        enabled: false,
      },
    ],
  };
};

export const getPreChatFields = ({
  preChatFormOptions,
  customAttributes = [],
}) => {
  if (
    !isEmptyObject(preChatFormOptions) &&
    'pre_chat_fields' in preChatFormOptions
  ) {
    return preChatFormOptions;
  }
  const {
    require_email: requireEmail,
    pre_chat_message: preChatMessage,
  } = preChatFormOptions;
  const standardFields = getStandardFields({
    requireEmail,
    emailEnabled: requireEmail,
    preChatMessage,
  });
  const customFields = getCustomFields({ standardFields, customAttributes });
  const finalFields = {
    pre_chat_message: standardFields.pre_chat_message,
    pre_chat_fields: [...standardFields.pre_chat_fields, ...customFields],
  };

  return finalFields;
};
