import { INBOX_TYPES } from 'shared/mixins/inboxMixin';
import { isEmptyObject } from 'dashboard/helper/commons';
import i18n from 'widget/i18n/index';

const standardFieldKeys = {
  emailAddress: {
    key: 'EMAIL_ADDRESS',
    label: 'Email Id',
    placeholder: 'Please enter your email address',
  },
  fullName: {
    key: 'FULL_NAME',
    label: 'Full Name',
    placeholder: 'Please enter your full name',
  },
  phoneNumber: {
    key: 'PHONE_NUMBER',
    label: 'Phone Number',
    placeholder: 'Please enter your phone number',
  },
};
export const getTranslations = ({ key, label, placeholder }) => {
  let translations = [];
  Object.keys(i18n).forEach(locale => {
    const translation = {
      locale,
      label: i18n[locale].PRE_CHAT_FORM.FIELDS[key]
        ? i18n[locale].PRE_CHAT_FORM.FIELDS[key].LABEL
        : label,
      placeholder: i18n[locale].PRE_CHAT_FORM.FIELDS[key]
        ? i18n[locale].PRE_CHAT_FORM.FIELDS[key].PLACEHOLDER
        : placeholder,
    };
    translations = [...translations, translation];
  });
  return translations;
};

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
        placeholder: attribute.attribute_display_name,
        name: attribute.attribute_key,
        type: attribute.attribute_display_type,
        values: attribute.attribute_values,
        field_type: 'custom',
        required: false,
        enabled: false,
        translations: getTranslations({
          key: attribute.attribute_key,
          label: attribute.attribute_display_name,
          placeholder: attribute.attribute_display_name,
        }),
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
        placeholder: 'Please enter your email address',
        name: 'emailAddress',
        type: 'email',
        field_type: 'standard',
        required: requireEmail || false,
        enabled: emailEnabled || false,
        locale: 'en',
        translations: getTranslations({
          key: 'EMAIL_ADDRESS',
          label: 'Email Id',
          placeholder: 'Please enter your email address',
        }),
      },
      {
        label: 'Full name',
        placeholder: 'Please enter your full name',
        name: 'fullName',
        type: 'text',
        field_type: 'standard',
        required: false,
        enabled: false,
        translations: getTranslations({
          key: 'FULL_NAME',
          label: 'Full Name',
          placeholder: 'Please enter your full name',
        }),
      },
      {
        label: 'Phone number',
        placeholder: 'Please enter your phone number',
        name: 'phoneNumber',
        type: 'text',
        field_type: 'standard',
        required: false,
        enabled: false,
        translations: getTranslations({
          key: 'PHONE_NUMBER',
          label: 'Phone Number',
          placeholder: 'Please enter your phone number',
        }),
      },
    ],
  };
};

export const getPreChatFields = ({
  preChatFormOptions = {},
  customAttributes = [],
}) => {
  if (
    !isEmptyObject(preChatFormOptions) &&
    'pre_chat_fields' in preChatFormOptions
  ) {
    const { pre_chat_message, pre_chat_fields } = preChatFormOptions;

    const preChatFields = pre_chat_fields.map(item => {
      return {
        ...item,
        translations:
          item.translations || standardFieldKeys[item.name]
            ? getTranslations({
                key: standardFieldKeys[item.name].key,
                label: standardFieldKeys[item.name].label,
                placeholder: standardFieldKeys[item.name].placeholder,
              })
            : [],
      };
    });
    const customFields = getCustomFields({
      standardFields: { pre_chat_fields: preChatFields },
      customAttributes,
    });
    const finalFields = {
      pre_chat_message,
      pre_chat_fields: [...preChatFields, ...customFields],
    };

    return finalFields;
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
  const customFields = getCustomFields({
    standardFields,
    customAttributes,
  });
  const finalFields = {
    pre_chat_message: standardFields.pre_chat_message,
    pre_chat_fields: [...standardFields.pre_chat_fields, ...customFields],
  };

  return finalFields;
};
