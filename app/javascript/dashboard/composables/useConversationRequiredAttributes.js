import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { ATTRIBUTE_TYPES } from 'dashboard/components-next/ConversationWorkflow/constants';

const attributeBlank = (attrs, key, type) => {
  if (type === ATTRIBUTE_TYPES.CHECKBOX || type === 'checkbox') {
    return !(key in attrs);
  }
  const value = attrs[key];
  if (Array.isArray(value)) return value.length === 0;
  return value == null || String(value).trim() === '';
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
 * Keys required to change conversation status, from business_rules + legacy list.
 * Conditional: if-then only when when_attribute already matches.
 */
export function requiredKeysForStatusChange({
  businessRules = [],
  legacyKeys = [],
  targetStatus = 'resolved',
  customAttributes = {},
} = {}) {
  const keys = new Set();

  (legacyKeys || []).forEach(key => {
    if (key) keys.add(String(key));
  });

  (businessRules || [])
    .filter(rule => rule?.enabled !== false)
    .forEach(rule => {
      const config = rule.config || {};
      if (rule.type === 'require_attributes_on_status') {
        if (String(config.status || '') !== String(targetStatus)) return;
        (config.attribute_keys || []).forEach(key => {
          if (key) keys.add(String(key));
        });
      }
      if (rule.type === 'if_attribute_then_require') {
        const onStatus = config.on_status || 'resolved';
        if (String(onStatus) !== String(targetStatus)) return;
        const whenKey = config.when_attribute;
        if (!whenKey) return;
        if (!attributeMatches(customAttributes, whenKey, config.when_values)) {
          return;
        }
        (config.require_attribute_keys || []).forEach(key => {
          if (key) keys.add(String(key));
        });
      }
    });

  return [...keys];
}

export function useConversationRequiredAttributes() {
  const { currentAccount, accountId } = useAccount();
  const isFeatureEnabledonAccount = useMapGetter(
    'accounts/isFeatureEnabledonAccount'
  );
  const conversationAttributes = useMapGetter(
    'attributes/getConversationAttributes'
  );

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

  const allAttributeOptions = computed(() =>
    (conversationAttributes.value || [])
      .filter(attribute => !attribute.formula)
      .map(attribute => ({
        ...attribute,
        value: attribute.attributeKey,
        label: attribute.attributeDisplayName,
        type: attribute.attributeDisplayType,
        attributeValues: attribute.attributeValues,
      }))
  );

  const requiredAttributes = computed(() =>
    requiredAttributeKeys.value
      .map(key =>
        allAttributeOptions.value.find(attribute => attribute.value === key)
      )
      .filter(Boolean)
  );

  const checkMissingAttributes = (
    conversationCustomAttributes = {},
    targetStatus = 'resolved'
  ) => {
    const keys = requiredKeysForStatusChange({
      businessRules: businessRules.value,
      legacyKeys: legacyAttributeKeys.value,
      targetStatus,
      customAttributes: conversationCustomAttributes,
    });

    if (!keys.length) {
      return { hasMissing: false, missing: [], all: [] };
    }

    const all = keys
      .map(key =>
        allAttributeOptions.value.find(attribute => attribute.value === key)
      )
      .filter(Boolean);

    const missing = all.filter(attribute =>
      attributeBlank(
        conversationCustomAttributes,
        attribute.value,
        attribute.type
      )
    );

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
