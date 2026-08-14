/**
 * Leading icons and grouped section headers for the attribute picker rendered by FilterSelect,
 * so the conversation and contact filters read like the Captain audience picker. The icon table is
 * shared with the automation condition picker, which draws from the same attribute keys.
 */

// Icon per known attribute key, across the conversation, contact and automation attributes.
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
  referer: 'i-lucide-link',
  // Automation attributes
  message_type: 'i-lucide-message-square',
  private_note: 'i-lucide-sticky-note',
  content: 'i-lucide-message-square-text',
  mail_subject: 'i-lucide-mail-open',
  conversation_language: 'i-lucide-languages',
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
 * Resolve the leading icon for an attribute. Only custom attributes carry a display type, so they
 * are iconed by that; every other attribute is iconed by its key.
 * @param {{attributeKey?: string, attributeDisplayType?: string}} type
 * @returns {string} Icon class.
 */
export const getAttributeIcon = ({ attributeKey, attributeDisplayType }) =>
  CUSTOM_TYPE_ICONS[attributeDisplayType] ||
  ATTRIBUTE_ICONS[attributeKey] ||
  DEFAULT_ICON;

// The order groups appear in, keyed by attributeModel. Labels resolve against the caller's i18n
// namespace so the conversation and contact filters can name their own sections.
const GROUPS = [
  { model: 'standard', labelKey: 'STANDARD_FILTERS' },
  { model: 'additional', labelKey: 'ADDITIONAL_FILTERS' },
  { model: 'customAttributes', labelKey: 'CUSTOM_ATTRIBUTES' },
];

const KNOWN_MODELS = GROUPS.map(({ model }) => model);

/**
 * Attach a leading icon to each filter type and split them into sections separated by disabled
 * header entries, which FilterSelect renders as non-clickable section titles.
 * @param {Object[]} filterTypes - Flat list of FilterType entries.
 * @param {Function} t - vue-i18n translate function.
 * @param {string} [i18nKey] - Namespace holding the GROUPS labels.
 * @returns {Object[]} Grouped list of header and icon-enriched entries.
 */
export const groupFilterTypes = (filterTypes, t, i18nKey = 'FILTER') => {
  const modelOf = type => type.attributeModel || 'standard';
  const withIcon = type => ({
    ...type,
    icon: type.icon || getAttributeIcon(type),
  });

  const grouped = GROUPS.flatMap(({ model, labelKey }) => {
    const group = filterTypes.filter(type => modelOf(type) === model);
    if (!group.length) return [];
    return [
      {
        value: `__group_${model}`,
        label: t(`${i18nKey}.GROUPS.${labelKey}`),
        disabled: true,
      },
      ...group.map(withIcon),
    ];
  });

  // Append attributes with an unexpected model rather than dropping them silently.
  const ungrouped = filterTypes.filter(
    type => !KNOWN_MODELS.includes(modelOf(type))
  );

  return [...grouped, ...ungrouped.map(withIcon)];
};
