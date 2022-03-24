import { isEmptyObject } from 'dashboard/helper/commons';
import i18n from 'widget/i18n/index';
const defaultTranslations = Object.fromEntries(
  Object.entries(i18n).filter(([key]) => key.includes('en'))
).en;

export const standardFieldKeys = {
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

export const getLabel = ({ key, label }) => {
  return defaultTranslations.PRE_CHAT_FORM.FIELDS[key]
    ? defaultTranslations.PRE_CHAT_FORM.FIELDS[key].LABEL
    : label;
};
export const getPlaceHolder = ({ key, placeholder }) => {
  return defaultTranslations.PRE_CHAT_FORM.FIELDS[key]
    ? defaultTranslations.PRE_CHAT_FORM.FIELDS[key].PLACEHOLDER
    : placeholder;
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
        field_type: attribute.attribute_model,
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
        label: getLabel({ key: 'emailAddress', label: 'Email Address' }),
        placeholder: getPlaceHolder({
          key: 'emailAddress',
          placeholder: 'Please enter your email address',
        }),
        name: 'emailAddress',
        type: 'email',
        field_type: 'standard',
        required: requireEmail || false,
        enabled: emailEnabled || false,
      },
      {
        label: getLabel({ key: 'fullName', label: 'Full name' }),
        placeholder: getPlaceHolder({
          key: 'fullName',
          placeholder: 'Please enter your full name',
        }),
        name: 'fullName',
        type: 'text',
        field_type: 'standard',
        required: false,
        enabled: false,
      },
      {
        label: getLabel({ key: 'phoneNumber', label: 'Phone number' }),
        placeholder: getPlaceHolder({
          key: 'phoneNumber',
          placeholder: 'Please enter your phone number',
        }),
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
        label: getLabel({
          key: standardFieldKeys[item.name]
            ? standardFieldKeys[item.name].key
            : item.name,
          label: item.label ? item.label : item.name,
        }),
        placeholder: getPlaceHolder({
          key: standardFieldKeys[item.name]
            ? standardFieldKeys[item.name].key
            : item.name,
          placeholder: item.placeholder ? item.placeholder : item.name,
        }),
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
