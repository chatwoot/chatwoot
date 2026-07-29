import { isNumericCustomDisplayType } from 'dashboard/helper/contactTableColumns';

export const STANDARD_CONVERSATION_SORT_KEYS = [
  'last_activity_at_asc',
  'last_activity_at_desc',
  'created_at_desc',
  'created_at_asc',
  'unread',
  'priority_desc',
  'priority_asc',
  'priority_desc_created_at_asc',
  'waiting_since_asc',
  'waiting_since_desc',
  'last_message_from_asc',
  'last_message_from_desc',
];

/**
 * Build standard sort options for conversation lists.
 * @param {(key: string) => string} t - i18n translate
 */
export const buildStandardConversationSortOptions = t =>
  STANDARD_CONVERSATION_SORT_KEYS.map(value => ({
    label: t(`CHAT_LIST.SORT_ORDER_ITEMS.${value}.TEXT`),
    value,
  }));

/**
 * Build custom-attribute sort options (`custom:key` / `-custom:key`).
 * @param {Array} attributeDefinitions - conversation_attribute defs
 * @param {(key: string, params?: object) => string} t
 */
export const buildCustomConversationSortOptions = (
  attributeDefinitions = [],
  t = () => ''
) => {
  const options = [];

  (attributeDefinitions || []).forEach(def => {
    const attributeKey = def.attribute_key || def.attributeKey;
    const label = def.attribute_display_name || def.attributeDisplayName;
    if (!attributeKey || !label) return;

    const displayType =
      def.attribute_display_type ?? def.attributeDisplayType ?? 'text';
    const numeric = isNumericCustomDisplayType(displayType) || !!def.formula;

    options.push({
      label: t('CHAT_LIST.SORT_ORDER_ITEMS.custom_asc.TEXT', {
        attribute: label,
      }),
      value: `custom:${attributeKey}`,
      attributeKey,
      numeric,
    });
    options.push({
      label: t('CHAT_LIST.SORT_ORDER_ITEMS.custom_desc.TEXT', {
        attribute: label,
      }),
      value: `-custom:${attributeKey}`,
      attributeKey,
      numeric,
    });
  });

  return options;
};

export const buildConversationSortOptions = (t, attributeDefinitions = []) => [
  ...buildStandardConversationSortOptions(t),
  ...buildCustomConversationSortOptions(attributeDefinitions, t),
];

/** Convert table sort state (sortKey + order '-') to API/sortComparator key */
export const toConversationSortParam = (sortKey, ordering = '') => {
  if (!sortKey) return 'last_activity_at_desc';
  if (sortKey.startsWith('custom:')) {
    return ordering === '-' ? `-${sortKey}` : sortKey;
  }
  // Standard keys already include direction suffix except when used as column keys
  const direction = ordering === '-' ? 'desc' : 'asc';
  if (
    [
      'last_activity_at',
      'created_at',
      'priority',
      'waiting_since',
      'last_message_from',
    ].includes(sortKey)
  ) {
    return `${sortKey}_${direction}`;
  }
  return sortKey;
};
