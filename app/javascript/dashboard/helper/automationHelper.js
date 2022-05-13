import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_3,
  OPERATOR_TYPES_4,
} from '../routes/dashboard/settings/automation/operators';

export const getCustomAttributeInputType = key => {
  const customAttributeMap = {
    date: 'date',
    text: 'plain_text',
    list: 'search_select',
    checkbox: 'search_select',
  };

  return customAttributeMap[key] || 'plain_text';
};

export const isACustomAttribute = (customAttributes, key) => {
  return customAttributes.find(attr => {
    return attr.attribute_key === key;
  });
};

export const getCustomAttributeListDropdownValues = (
  customAttributes,
  type
) => {
  return customAttributes
    .find(attr => attr.attribute_key === type)
    .attribute_values.map(item => {
      return {
        id: item,
        name: item,
      };
    });
};

export const getCustomAttributeCheckboxDropdownValues = () => {
  return [
    {
      id: true,
      name: this.$t('FILTER.ATTRIBUTE_LABELS.TRUE'),
    },
    {
      id: false,
      name: this.$t('FILTER.ATTRIBUTE_LABELS.FALSE'),
    },
  ];
};

export const isCustomAttributeCheckbox = (customAttributes, key) => {
  return customAttributes.find(attr => {
    return (
      attr.attribute_key === key && attr.attribute_display_type === 'checkbox'
    );
  });
};

export const isCustomAttributeList = (customAttributes, type) => {
  return customAttributes.find(attr => {
    return (
      attr.attribute_key === type && attr.attribute_display_type === 'list'
    );
  });
};

export const getOperatorTypes = key => {
  const operatorMap = {
    list: OPERATOR_TYPES_1,
    text: OPERATOR_TYPES_3,
    number: OPERATOR_TYPES_1,
    link: OPERATOR_TYPES_1,
    date: OPERATOR_TYPES_4,
    checkbox: OPERATOR_TYPES_1,
  };

  return operatorMap[key] || OPERATOR_TYPES_1;
};
