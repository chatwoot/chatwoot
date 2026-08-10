/**
 * Leading icons and grouped section headers for the attribute picker rendered by FilterSelect.
 * Shared by the conversation, contact, automation and Captain audience filter builders so every
 * attribute dropdown reads the same.
 */

// Icon per known attribute key, across the conversation, contact and automation filters.
const ATTRIBUTE_ICONS = {
  // Contact attributes
  name: 'i-lucide-user',
  email: 'i-lucide-mail',
  phone_number: 'i-lucide-phone',
  identifier: 'i-lucide-fingerprint',
  country_code: 'i-lucide-flag',
  city: 'i-lucide-map-pin',
  company_name: 'i-lucide-building-2',
  blocked: 'i-lucide-ban',
  hmac_verified: 'i-lucide-user-check',
  // Conversation attributes
  status: 'i-lucide-circle-dot',
  priority: 'i-lucide-signal-high',
  assignee_id: 'i-lucide-user-round',
  inbox_id: 'i-lucide-inbox',
  team_id: 'i-lucide-users-round',
  contact_id: 'i-lucide-contact',
  display_id: 'i-lucide-hash',
  campaign_id: 'i-lucide-megaphone',
  browser_language: 'i-lucide-globe',
  conversation_language: 'i-lucide-languages',
  referer: 'i-lucide-link',
  // Message attributes, used by the automation filter
  message_type: 'i-lucide-message-square',
  private_note: 'i-lucide-lock',
  content: 'i-lucide-text',
  mail_subject: 'i-lucide-mail-open',
  // Shared
  labels: 'i-lucide-tags',
  created_at: 'i-lucide-calendar',
  last_activity_at: 'i-lucide-activity',
};

// Icon per custom attribute display type.
const CUSTOM_TYPE_ICONS = {
  text: 'i-lucide-type',
  number: 'i-lucide-hash',
  currency: 'i-lucide-banknote',
  percent: 'i-lucide-percent',
  link: 'i-lucide-link',
  date: 'i-lucide-calendar',
  list: 'i-lucide-list',
  checkbox: 'i-lucide-square-check',
};

const DEFAULT_ICON = 'i-lucide-tag';

/**
 * Resolve the leading icon for a single filter type.
 * @param {Object} type - A FilterType entry.
 * @returns {string} The icon class to render.
 */
export const getAttributeIcon = type => {
  if (type.attributeModel === 'customAttributes') {
    return CUSTOM_TYPE_ICONS[type.attributeDisplayType] || DEFAULT_ICON;
  }
  return ATTRIBUTE_ICONS[type.attributeKey] || DEFAULT_ICON;
};

/**
 * Attach the leading icon to each filter type, leaving an icon the builder already set alone.
 * @param {Object[]} filterTypes - FilterType entries.
 * @returns {Object[]} The same entries, each carrying an icon.
 */
export const withAttributeIcons = filterTypes =>
  filterTypes.map(type => ({
    ...type,
    icon: type.icon || getAttributeIcon(type),
  }));

/**
 * A non-clickable section title, which FilterSelect renders from the disabled flag.
 * @param {string} id - Unique suffix for the header's option value.
 * @param {string} label - Translated section title.
 * @returns {Object} A disabled option entry.
 */
export const sectionHeader = (id, label) => ({
  value: `__group_${id}`,
  label,
  disabled: true,
});

// The order groups appear in, keyed by attributeModel. Labels resolve against the caller's i18n
// namespace so the conversation and contact filters can name their own sections.
const GROUPS = [
  { model: 'standard', labelKey: 'STANDARD_FILTERS' },
  { model: 'additional', labelKey: 'ADDITIONAL_FILTERS' },
  { model: 'customAttributes', labelKey: 'CUSTOM_ATTRIBUTES' },
];

const KNOWN_MODELS = GROUPS.map(({ model }) => model);

/**
 * Split filter types into sections by attributeModel, each introduced by a header.
 * Surfaces that group along a different axis compose withAttributeIcons and sectionHeader instead.
 * @param {Object[]} filterTypes - Flat list of FilterType entries.
 * @param {Function} t - vue-i18n translate function.
 * @param {string} [i18nKey] - Namespace holding the GROUPS labels.
 * @returns {Object[]} Grouped list of header and icon-enriched entries.
 */
export const groupFilterTypes = (filterTypes, t, i18nKey = 'FILTER') => {
  const modelOf = type => type.attributeModel || 'standard';

  const grouped = GROUPS.flatMap(({ model, labelKey }) => {
    const group = filterTypes.filter(type => modelOf(type) === model);
    if (!group.length) return [];
    return [
      sectionHeader(model, t(`${i18nKey}.GROUPS.${labelKey}`)),
      ...withAttributeIcons(group),
    ];
  });

  // Append attributes with an unexpected model rather than dropping them silently.
  const ungrouped = filterTypes.filter(
    type => !KNOWN_MODELS.includes(modelOf(type))
  );

  return [...grouped, ...withAttributeIcons(ungrouped)];
};
