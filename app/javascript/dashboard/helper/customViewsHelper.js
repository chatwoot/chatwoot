export const getInputType = (key, operator, filterTypes) => {
  if (key === 'created_at' || key === 'last_activity_at')
    if (operator === 'days_before') return 'plain_text';
  const type = filterTypes.find(filter => filter.attributeKey === key);
  return type?.inputType;
};

const generateCustomAttributesInputType = type => {
  const filterInputTypes = {
    text: 'string',
    number: 'string',
    date: 'string',
    checkbox: 'multi_select',
    list: 'multi_select',
    link: 'string',
  };
  return filterInputTypes[type];
};

export const getAttributeInputType = (key, allCustomAttributes) => {
  const customAttribute = allCustomAttributes.find(
    attr => attr.attribute_key === key
  );
  const { attribute_display_type } = customAttribute;
  const filterInputTypes = generateCustomAttributesInputType(
    attribute_display_type
  );
  return filterInputTypes;
};
