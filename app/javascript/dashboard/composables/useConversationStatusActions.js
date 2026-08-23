import { ref, computed } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useBusinessRulesStatusGuard } from 'dashboard/composables/useBusinessRulesStatusGuard';
import { useFormatBusinessRuleError } from 'dashboard/composables/useFormatBusinessRuleError';
import wootConstants from 'dashboard/constants/globals';

export function useConversationStatusActions() {
  const store = useStore();
  const getters = useStoreGetters();
  const { t } = useI18n();
  const { checkStatusChange } = useBusinessRulesStatusGuard();
  const formatBusinessRuleError = useFormatBusinessRuleError();

  const isLoading = ref(false);
  const resolveAttributesModalRef = ref(null);

  const currentChat = computed(() => getters.getSelectedChat.value);

  const isPending = computed(
    () => currentChat.value?.status === wootConstants.STATUS_TYPE.PENDING
  );
  const isSnoozed = computed(
    () => currentChat.value?.status === wootConstants.STATUS_TYPE.SNOOZED
  );

  const showAdditionalActions = computed(
    () => !isPending.value && !isSnoozed.value
  );

  const showGuardAlerts = guard => {
    if (guard.forbiddenLabels?.length) {
      useAlert(
        t('BUSINESS_RULES.STATUS_ERRORS.forbidden_label', {
          label: guard.forbiddenLabels[0],
        })
      );
      return true;
    }
    if (guard.needsAssignee) {
      useAlert(t('BUSINESS_RULES.STATUS_ERRORS.missing_assignee'));
      return true;
    }
    return false;
  };

  const toggleStatus = (status, snoozedUntil, customAttributes = null) => {
    isLoading.value = true;

    const payload = {
      conversationId: currentChat.value.id,
      status,
      snoozedUntil,
    };

    if (customAttributes) {
      payload.customAttributes = customAttributes;
    }

    return store
      .dispatch('toggleStatus', payload)
      .then(() => {
        useAlert(t('CONVERSATION.CHANGE_STATUS'));
      })
      .catch(error => {
        const serverMessage =
          error?.response?.data?.message ||
          error?.response?.data?.error ||
          error?.message;
        useAlert(
          formatBusinessRuleError(serverMessage) ||
            t('CONVERSATION.CHANGE_STATUS_FAILED')
        );
      })
      .finally(() => {
        isLoading.value = false;
      });
  };

  const openSnoozeModal = () => {
    const guard = checkStatusChange(
      currentChat.value,
      wootConstants.STATUS_TYPE.SNOOZED
    );
    if (showGuardAlerts(guard)) return;

    if (guard.missingAttributes?.length) {
      resolveAttributesModalRef.value?.open(
        guard.requiredAttributes?.length
          ? guard.requiredAttributes
          : guard.missingAttributes,
        currentChat.value.custom_attributes || {},
        {
          id: currentChat.value.id,
          status: wootConstants.STATUS_TYPE.SNOOZED,
          openSnoozeAfter: true,
          conversation: currentChat.value,
        },
        currentChat.value.meta?.sender?.custom_attributes || {}
      );
      return;
    }

    const ninja = document.querySelector('ninja-keys');
    ninja?.open({ parent: 'snooze_conversation' });
  };

  const attemptStatusChange = (status, snoozedUntil = null) => {
    const guard = checkStatusChange(currentChat.value, status);
    if (showGuardAlerts(guard)) return;

    if (guard.missingAttributes?.length) {
      resolveAttributesModalRef.value?.open(
        guard.requiredAttributes?.length
          ? guard.requiredAttributes
          : guard.missingAttributes,
        currentChat.value.custom_attributes || {},
        {
          id: currentChat.value.id,
          snoozedUntil,
          status,
          conversation: currentChat.value,
        },
        currentChat.value.meta?.sender?.custom_attributes || {}
      );
      return;
    }

    toggleStatus(status, snoozedUntil);
  };

  const handleResolveWithAttributes = async ({
    attributes,
    contactAttributes = {},
    context,
  }) => {
    if (!context) return;

    const contactId = currentChat.value.meta?.sender?.id;
    if (contactId && Object.keys(contactAttributes || {}).length) {
      const existingContactAttrs =
        currentChat.value.meta?.sender?.custom_attributes || {};
      try {
        await store.dispatch('contacts/update', {
          id: contactId,
          customAttributes: {
            ...existingContactAttrs,
            ...contactAttributes,
          },
        });
      } catch (error) {
        useAlert(t('CONVERSATION.CHANGE_STATUS_FAILED'));
        return;
      }
    }

    const currentCustomAttributes = currentChat.value.custom_attributes || {};
    const mergedAttributes = { ...currentCustomAttributes, ...attributes };

    if (context.openSnoozeAfter) {
      try {
        await store.dispatch('updateCustomAttributes', {
          conversationId: currentChat.value.id,
          customAttributes: mergedAttributes,
        });
      } catch (error) {
        useAlert(t('CONVERSATION.CHANGE_STATUS_FAILED'));
        return;
      }
      const ninja = document.querySelector('ninja-keys');
      ninja?.open({ parent: 'snooze_conversation' });
      return;
    }

    toggleStatus(
      context.status || wootConstants.STATUS_TYPE.RESOLVED,
      context.snoozedUntil,
      mergedAttributes
    );
  };

  return {
    currentChat,
    isLoading,
    isPending,
    isSnoozed,
    showAdditionalActions,
    resolveAttributesModalRef,
    toggleStatus,
    openSnoozeModal,
    attemptStatusChange,
    handleResolveWithAttributes,
  };
}
