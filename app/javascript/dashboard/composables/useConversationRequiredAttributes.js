import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';

/**
 * Composable for managing conversation required attributes workflow
 *
 * This handles the logic for checking if conversations have all required
 * custom attributes filled before they can be resolved.
 */
export function useConversationRequiredAttributes() {
  const { currentAccount } = useAccount();
  const conversationAttributes = useMapGetter(
    'attributes/getConversationAttributes'
  );

  const requiredAttributeKeys = computed(
    () => currentAccount.value?.settings?.conversation_required_attributes || []
  );

  const allAttributeOptions = computed(() =>
    (conversationAttributes.value || []).map(attribute => ({
      ...attribute,
      value: attribute.attributeKey,
      label: attribute.attributeDisplayName,
      type: attribute.attributeDisplayType,
      attribute_values: attribute.attributeValues,
    }))
  );

  /**
   * Get the full attribute definitions for only the required attributes
   * Filters allAttributeOptions to only include attributes marked as required
   */
  const requiredAttributes = computed(
    () =>
      requiredAttributeKeys.value
        .map(key =>
          allAttributeOptions.value.find(attribute => attribute.value === key)
        )
        .filter(Boolean) // Remove any undefined attributes (deleted attributes)
  );

  /**
   * Check if a conversation is missing any required attributes
   *
   * @param {Object} conversationCustomAttributes - Current conversation's custom attributes
   * @returns {Object} - Analysis result with missing attributes info
   */
  const checkMissingAttributes = (conversationCustomAttributes = {}) => {
    // If no attributes are required, conversation can be resolved
    if (!requiredAttributes.value.length) {
      return { hasMissing: false, missing: [] };
    }

    // Find attributes that are missing or empty
    const missing = requiredAttributes.value.filter(attribute => {
      const value = conversationCustomAttributes[attribute.value];
      // Consider null, undefined, empty string, or whitespace-only as missing
      return !value || String(value).trim() === '';
    });

    return {
      hasMissing: missing.length > 0,
      missing,
      all: requiredAttributes.value,
    };
  };

  return {
    requiredAttributeKeys,
    requiredAttributes,
    checkMissingAttributes,
  };
}
