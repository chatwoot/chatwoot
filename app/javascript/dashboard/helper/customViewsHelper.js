export const getInputType = (key, operator, filterTypes) => {
  if (key === 'created_at' || key === 'last_activity_at')
    if (operator === 'days_before') return 'plain_text';
  const type = filterTypes.find(filter => filter.attributeKey === key);
  return type?.inputType;
};

export const generateCustomAttributesInputType = type => {
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

export const getValuesName = (values, list, idKey, nameKey) => {
  const item = list?.find(v => v[idKey] === values[0]);
  return {
    id: values[0],
    name: item ? item[nameKey] : values[0],
  };
};

export const getValuesForStatus = values => {
  return values.map(value => ({ id: value, name: value }));
};

const getValuesForLabels = (values, labels) => {
  const selectedLabels = labels.filter(label => values.includes(label.title));
  return selectedLabels.map(({ title }) => ({
    id: title,
    name: title,
  }));
};

const getValuesForLanguages = (values, languages) => {
  const selectedLanguages = languages.filter(language =>
    values.includes(language.id)
  );
  return selectedLanguages.map(({ id, name }) => ({
    id: id.toLowerCase(),
    name: name,
  }));
};

const getValuesForCountries = (values, countries) => {
  const selectedCountries = countries.filter(country =>
    values.includes(country.id)
  );
  return selectedCountries.map(({ id, name }) => ({
    id: id,
    name: name,
  }));
};

export const getValuesForFilter = (filter, params) => {
  const { attribute_key, values } = filter;
  const { languages, countries, agents, inboxes, teams, campaigns, labels } =
    params;
  switch (attribute_key) {
    case 'status':
      return getValuesForStatus(values);
    case 'assignee_id':
      return getValuesName(values, agents, 'id', 'name');
    case 'inbox_id':
      return getValuesName(values, inboxes, 'id', 'name');
    case 'team_id':
      return getValuesName(values, teams, 'id', 'name');
    case 'campaign_id':
      return getValuesName(values, campaigns, 'id', 'title');
    case 'labels': {
      return getValuesForLabels(values, labels);
    }
    case 'browser_language': {
      return getValuesForLanguages(values, languages);
    }
    case 'country_code': {
      return getValuesForCountries(values, countries);
    }
    default:
      return { id: values[0], name: values[0] };
  }
};

export const generateValuesForEditCustomViews = (filter, params) => {
  const { attribute_key, filter_operator, values } = filter;
  const { filterTypes, allCustomAttributes } = params;
  const inboxType = getInputType(attribute_key, filter_operator, filterTypes);

  if (inboxType === undefined) {
    const filterInputTypes = getAttributeInputType(
      attribute_key,
      allCustomAttributes
    );
    return filterInputTypes === 'string'
      ? values[0].toString()
      : { id: values[0], name: values[0] };
  }

  return inboxType === 'multi_select' || inboxType === 'search_select'
    ? getValuesForFilter(filter, params)
    : values[0].toString();
};
