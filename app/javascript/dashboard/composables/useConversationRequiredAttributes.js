import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { ATTRIBUTE_TYPES } from 'dashboard/components-next/ConversationWorkflow/constants';

/**
 * Composable for managing conversation required attributes workflow
 *
 * This handles the logic for checking if conversations have all required
 * custom attributes filled before they can be resolved.
 */
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

  const requiredAttributeKeys = computed(() => {
    if (!isFeatureEnabled.value) return [];
    return (
      currentAccount.value?.settings?.conversation_required_attributes || []
    );
  });

  const allAttributeOptions = computed(() =>
    (conversationAttributes.value || []).map(attribute => ({
      ...attribute,
      value: attribute.attributeKey,
      label: attribute.attributeDisplayName,
      type: attribute.attributeDisplayType,
      attributeValues: attribute.attributeValues,
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

      // A checkbox is filled once true or false is picked. An explicit null is
      // an unanswered prompt, which is how the modal and the backend read it.
      if (attribute.type === ATTRIBUTE_TYPES.CHECKBOX) {
        return value == null;
      }

      // For other attribute types, only consider null, undefined, empty string, or whitespace-only as missing
      // Allow falsy values like 0, false as they are valid filled values
      return value == null || String(value).trim() === '';
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
