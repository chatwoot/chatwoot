import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { ATTRIBUTE_TYPES } from 'dashboard/components-next/ConversationWorkflow/constants';

const NUMERIC_TYPES = new Set([
  ATTRIBUTE_TYPES.NUMBER,
  ATTRIBUTE_TYPES.CURRENCY,
  ATTRIBUTE_TYPES.PERCENT,
  'number',
  'currency',
  'percent',
]);

export const attributeBlank = (attrs, key, type) => {
  if (type === ATTRIBUTE_TYPES.CHECKBOX || type === 'checkbox') {
    return !(key in attrs);
  }
  const value = attrs[key];
  if (Array.isArray(value)) return value.length === 0;
  if (value == null || String(value).trim() === '') return true;
  if (NUMERIC_TYPES.has(type)) {
    const numeric = Number(value);
    if (!Number.isNaN(numeric) && numeric === 0) return true;
  }
  return false;
};

const attributeMatches = (attrs, whenKey, whenValues) => {
  const value = attrs[whenKey];
  if (
    value == null ||
    value === '' ||
    (Array.isArray(value) && !value.length)
  ) {
    return false;
  }
  const values = (whenValues || []).map(String).filter(Boolean);
  if (!values.length) return true;
  const normalized = values.map(v => v.toLowerCase());
  return Array.isArray(value)
    ? value.map(String).some(v => normalized.includes(v.toLowerCase()))
    : normalized.includes(String(value).toLowerCase());
};

/**
 * Required attribute descriptors for a status change (conversation + contact).
 */
export function requiredKeysForStatusChange({
  businessRules = [],
  legacyKeys = [],
  targetStatus = 'resolved',
  customAttributes = {},
  contactCustomAttributes = {},
} = {}) {
  const items = [];
  const seen = new Set();

  const add = (key, attributeModel) => {
    if (!key) return;
    const id = `${attributeModel}:${key}`;
    if (seen.has(id)) return;
    seen.add(id);
    items.push({ key: String(key), attributeModel });
  };

  (legacyKeys || []).forEach(key => add(key, 'conversation'));

  (businessRules || [])
    .filter(rule => rule?.enabled !== false)
    .forEach(rule => {
      const config = rule.config || {};
      if (rule.type === 'require_attributes_on_status') {
        if (String(config.status || '') !== String(targetStatus)) return;
        (config.attribute_keys || []).forEach(key => add(key, 'conversation'));
        (config.contact_attribute_keys || []).forEach(key =>
          add(key, 'contact')
        );
      }
      if (rule.type === 'if_attribute_then_require') {
        const onStatus = config.on_status || 'resolved';
        if (String(onStatus) !== String(targetStatus)) return;
        const whenKey = config.when_attribute;
        if (!whenKey) return;
        const whenModel = config.when_attribute_model || 'conversation';
        const whenAttrs =
          whenModel === 'contact' ? contactCustomAttributes : customAttributes;
        if (!attributeMatches(whenAttrs, whenKey, config.when_values)) {
          return;
        }
        (config.require_attribute_keys || []).forEach(key =>
          add(key, 'conversation')
        );
        (config.require_contact_attribute_keys || []).forEach(key =>
          add(key, 'contact')
        );
      }
    });

  return items;
}

export function useConversationRequiredAttributes() {
  const { currentAccount, accountId } = useAccount();
  const isFeatureEnabledonAccount = useMapGetter(
    'accounts/isFeatureEnabledonAccount'
  );
  const conversationAttributes = useMapGetter(
    'attributes/getConversationAttributes'
  );
  const contactAttributes = useMapGetter('attributes/getContactAttributes');

  const isFeatureEnabled = computed(() =>
    isFeatureEnabledonAccount.value(
      accountId.value,
      FEATURE_FLAGS.CONVERSATION_REQUIRED_ATTRIBUTES
    )
  );

  const legacyAttributeKeys = computed(() => {
    if (!isFeatureEnabled.value) return [];
    return (
      currentAccount.value?.settings?.conversation_required_attributes || []
    );
  });

  const businessRules = computed(
    () => currentAccount.value?.settings?.business_rules || []
  );

  /** @deprecated use keys required for a specific status + attrs */
  const requiredAttributeKeys = computed(() => legacyAttributeKeys.value);

  const mapOptions = (attrs, attributeModel) =>
    (attrs || [])
      .filter(attribute => !attribute.formula)
      .map(attribute => ({
        ...attribute,
        value: attribute.attributeKey,
        label: attribute.attributeDisplayName,
        type: attribute.attributeDisplayType,
        attributeValues: attribute.attributeValues,
        attributeModel,
      }));

  const allAttributeOptions = computed(() => [
    ...mapOptions(conversationAttributes.value, 'conversation'),
    ...mapOptions(contactAttributes.value, 'contact'),
  ]);

  const requiredAttributes = computed(() =>
    requiredAttributeKeys.value
      .map(key =>
        allAttributeOptions.value.find(
          attribute =>
            attribute.value === key &&
            attribute.attributeModel === 'conversation'
        )
      )
      .filter(Boolean)
  );

  const checkMissingAttributes = (
    conversationCustomAttributes = {},
    targetStatus = 'resolved',
    contactCustomAttributes = {}
  ) => {
    const required = requiredKeysForStatusChange({
      businessRules: businessRules.value,
      legacyKeys: legacyAttributeKeys.value,
      targetStatus,
      customAttributes: conversationCustomAttributes,
      contactCustomAttributes,
    });

    if (!required.length) {
      return { hasMissing: false, missing: [], all: [] };
    }

    const all = required
      .map(({ key, attributeModel }) =>
        allAttributeOptions.value.find(
          attribute =>
            attribute.value === key &&
            attribute.attributeModel === attributeModel
        )
      )
      .filter(Boolean);

    const missing = all.filter(attribute => {
      const attrs =
        attribute.attributeModel === 'contact'
          ? contactCustomAttributes
          : conversationCustomAttributes;
      return attributeBlank(attrs, attribute.value, attribute.type);
    });

    return {
      hasMissing: missing.length > 0,
      missing,
      all,
    };
  };

  return {
    requiredAttributeKeys,
    requiredAttributes,
    checkMissingAttributes,
    businessRules,
  };
}
