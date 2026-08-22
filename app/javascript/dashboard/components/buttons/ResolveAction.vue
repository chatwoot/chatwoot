<script setup>
import { ref, computed } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useEmitter } from 'dashboard/composables/emitter';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useBusinessRulesStatusGuard } from 'dashboard/composables/useBusinessRulesStatusGuard';
import { useFormatBusinessRuleError } from 'dashboard/composables/useFormatBusinessRuleError';

import WootDropdownItem from 'shared/components/ui/dropdown/DropdownItem.vue';
import WootDropdownMenu from 'shared/components/ui/dropdown/DropdownMenu.vue';
import wootConstants from 'dashboard/constants/globals';
import {
  CMD_REOPEN_CONVERSATION,
  CMD_RESOLVE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

import ButtonGroup from 'dashboard/components-next/buttonGroup/ButtonGroup.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ConversationResolveAttributesModal from 'dashboard/components-next/ConversationWorkflow/ConversationResolveAttributesModal.vue';

const store = useStore();
const getters = useStoreGetters();
const { t } = useI18n();
const { checkStatusChange } = useBusinessRulesStatusGuard();
const formatBusinessRuleError = useFormatBusinessRuleError();

const arrowDownButtonRef = ref(null);
const isLoading = ref(false);
const resolveAttributesModalRef = ref(null);

const [showActionsDropdown, toggleDropdown] = useToggle();
const closeDropdown = () => toggleDropdown(false);
const openDropdown = () => toggleDropdown(true);

const currentChat = computed(() => getters.getSelectedChat.value);

const isOpen = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.OPEN
);
const isPending = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.PENDING
);
const isResolved = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.RESOLVED
);
const isSnoozed = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.SNOOZED
);

const showAdditionalActions = computed(
  () => !isPending.value && !isSnoozed.value
);

const showOpenButton = computed(() => {
  return isPending.value || isSnoozed.value;
});

const getConversationParams = () => {
  const allConversations = document.querySelectorAll(
    '.conversations-list .conversation'
  );

  const activeConversation = document.querySelector(
    'div.conversations-list div.conversation.active'
  );
  const activeConversationIndex = [...allConversations].indexOf(
    activeConversation
  );
  const lastConversationIndex = allConversations.length - 1;

  return {
    all: allConversations,
    activeIndex: activeConversationIndex,
    lastIndex: lastConversationIndex,
  };
};

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
  closeDropdown();
  isLoading.value = true;

  const payload = {
    conversationId: currentChat.value.id,
    status,
    snoozedUntil,
  };

  if (customAttributes) {
    payload.customAttributes = customAttributes;
  }

  store
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
  closeDropdown();
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

  // Snooze needs a time from the command bar — save attrs first, then open picker.
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

const onCmdOpenConversation = () => {
  attemptStatusChange(wootConstants.STATUS_TYPE.OPEN);
};

const onCmdResolveConversation = () => {
  attemptStatusChange(wootConstants.STATUS_TYPE.RESOLVED);
};

const keyboardEvents = {
  'Alt+KeyM': {
    action: () => arrowDownButtonRef.value?.$el.click(),
    allowOnFocusedInput: true,
  },
  'Alt+KeyE': {
    action: async event => {
      // Chrome on Windows treats Alt+E as a legacy shortcut for its own
      // menu (Alt+E / Alt+F both open "Customize and control Google
      // Chrome"). Without preventDefault, our resolve action still runs,
      // but Chrome's menu also opens on top of it.
      event.preventDefault();
      onCmdResolveConversation();
    },
  },
  '$mod+Alt+KeyE': {
    action: async event => {
      const { all, activeIndex, lastIndex } = getConversationParams();
      onCmdResolveConversation();

      if (activeIndex < lastIndex) {
        all[activeIndex + 1].click();
      } else if (all.length > 1) {
        all[0].click();
        document.querySelector('.conversations-list').scrollTop = 0;
      }
      event.preventDefault();
    },
  },
};

useKeyboardEvents(keyboardEvents);

useEmitter(CMD_REOPEN_CONVERSATION, onCmdOpenConversation);
useEmitter(CMD_RESOLVE_CONVERSATION, onCmdResolveConversation);
</script>

<template>
  <div class="flex relative justify-end items-center resolve-actions">
    <ButtonGroup
      class="flex-shrink-0 rounded-lg shadow outline-1 outline"
      :class="!showOpenButton ? 'outline-n-container' : 'outline-transparent'"
    >
      <Button
        v-if="isOpen"
        :label="t('CONVERSATION.HEADER.RESOLVE_ACTION')"
        size="sm"
        color="slate"
        no-animation
        class="ltr:rounded-r-none rtl:rounded-l-none !outline-0"
        :is-loading="isLoading"
        @click="onCmdResolveConversation"
      />
      <Button
        v-else-if="isResolved"
        :label="t('CONVERSATION.HEADER.REOPEN_ACTION')"
        size="sm"
        color="slate"
        no-animation
        class="ltr:rounded-r-none rtl:rounded-l-none !outline-0"
        :is-loading="isLoading"
        @click="onCmdOpenConversation"
      />
      <Button
        v-else-if="showOpenButton"
        :label="t('CONVERSATION.HEADER.OPEN_ACTION')"
        size="sm"
        color="slate"
        no-animation
        :is-loading="isLoading"
        @click="onCmdOpenConversation"
      />
      <Button
        v-if="showAdditionalActions"
        ref="arrowDownButtonRef"
        icon="i-lucide-chevron-down"
        :disabled="isLoading"
        size="sm"
        no-animation
        class="ltr:rounded-l-none rtl:rounded-r-none !outline-0"
        color="slate"
        trailing-icon
        @click="openDropdown"
      />
    </ButtonGroup>
    <div
      v-if="showActionsDropdown"
      v-on-clickaway="closeDropdown"
      class="border rounded-lg shadow-lg border-n-strong dark:border-n-strong box-content p-2 w-fit z-10 bg-n-alpha-3 backdrop-blur-[100px] absolute block left-auto top-full mt-0.5 start-0 xl:start-auto xl:end-0 max-w-[12.5rem] min-w-[9.75rem] [&_ul>li]:mb-0"
    >
      <WootDropdownMenu class="mb-0">
        <WootDropdownItem v-if="!isPending">
          <Button
            :label="t('CONVERSATION.RESOLVE_DROPDOWN.SNOOZE_UNTIL')"
            ghost
            slate
            sm
            start
            icon="i-lucide-alarm-clock-minus"
            class="w-full"
            @click="() => openSnoozeModal()"
          />
        </WootDropdownItem>
        <WootDropdownItem v-if="!isPending">
          <Button
            :label="t('CONVERSATION.RESOLVE_DROPDOWN.MARK_PENDING')"
            ghost
            slate
            sm
            start
            icon="i-lucide-circle-dot-dashed"
            class="w-full"
            @click="
              () => attemptStatusChange(wootConstants.STATUS_TYPE.PENDING)
            "
          />
        </WootDropdownItem>
      </WootDropdownMenu>
    </div>
    <ConversationResolveAttributesModal
      ref="resolveAttributesModalRef"
      @submit="handleResolveWithAttributes"
    />
  </div>
</template>
