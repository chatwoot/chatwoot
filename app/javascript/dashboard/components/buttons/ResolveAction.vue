<script setup>
import { ref, computed } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import {
  useStore,
  useStoreGetters,
  useMapGetter,
} from 'dashboard/composables/store';
import { useEmitter } from 'dashboard/composables/emitter';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useAccount } from 'dashboard/composables/useAccount';

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
const { currentAccount } = useAccount();
const conversationAttributes = useMapGetter(
  'attributes/getConversationAttributes'
);

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

const openSnoozeModal = () => {
  const ninja = document.querySelector('ninja-keys');
  ninja.open({ parent: 'snooze_conversation' });
};

const requiredAttributeKeys = computed(
  () => currentAccount.value?.settings?.conversation_required_attributes || []
);

const requiredAttributes = computed(() =>
  requiredAttributeKeys.value.map(key => {
    const definition = conversationAttributes.value?.find(
      attribute => attribute.attributeKey === key
    );
    if (!definition) {
      return {
        value: key,
        label: key,
        type: 'text',
        attribute_values: [],
      };
    }

    return {
      ...definition,
      value: definition.attributeKey,
      label: definition.attributeDisplayName,
      type: definition.attributeDisplayType,
    };
  })
);

const getMissingRequiredAttributes = () => {
  if (!currentChat.value?.id) return [];
  const existingValues = currentChat.value.custom_attributes || {};
  return requiredAttributes.value.filter(attribute => {
    const value = existingValues?.[attribute.value];
    return value === undefined || value === null || String(value) === '';
  });
};

const toggleStatusInternal = async (status, snoozedUntil = null) => {
  closeDropdown();
  isLoading.value = true;
  try {
    await store.dispatch('toggleStatus', {
      conversationId: currentChat.value.id,
      status,
      snoozedUntil,
    });
    useAlert(t('CONVERSATION.CHANGE_STATUS'));
  } finally {
    isLoading.value = false;
  }
};

const resolveWithAttributes = async customAttributes => {
  if (!currentChat.value?.id) return;
  try {
    isLoading.value = true;
    if (requiredAttributeKeys.value.length) {
      await store.dispatch('updateCustomAttributes', {
        conversationId: currentChat.value.id,
        customAttributes,
      });
    }
    await toggleStatusInternal(wootConstants.STATUS_TYPE.RESOLVED);
  } catch (error) {
    useAlert(t('CONVERSATION_WORKFLOW.REQUIRED_ATTRIBUTES.SAVE.ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const openResolveModal = () => {
  closeDropdown();
  if (!currentChat.value?.id) return;
  const missing = getMissingRequiredAttributes();
  if (!missing.length) {
    resolveWithAttributes(currentChat.value.custom_attributes || {});
    return;
  }
  resolveAttributesModalRef.value?.open(
    missing,
    currentChat.value.custom_attributes || {}
  );
};

const handleModalSubmit = async values => {
  if (!currentChat.value?.id) return;
  resolveAttributesModalRef.value?.close();
  await resolveWithAttributes({
    ...(currentChat.value.custom_attributes || {}),
    ...values,
  });
};

const toggleStatus = (status, snoozedUntil) => {
  closeDropdown();
  isLoading.value = true;
  store
    .dispatch('toggleStatus', {
      conversationId: currentChat.value.id,
      status,
      snoozedUntil,
    })
    .then(() => {
      useAlert(t('CONVERSATION.CHANGE_STATUS'));
      isLoading.value = false;
    });
};

const onCmdOpenConversation = () => {
  toggleStatus(wootConstants.STATUS_TYPE.OPEN);
};

const onCmdResolveConversation = () => {
  openResolveModal();
};

const keyboardEvents = {
  'Alt+KeyM': {
    action: () => arrowDownButtonRef.value?.$el.click(),
    allowOnFocusedInput: true,
  },
  'Alt+KeyE': {
    action: () => openResolveModal(),
  },
  '$mod+Alt+KeyE': {
    action: event => {
      openResolveModal();
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
    <ConversationResolveAttributesModal
      ref="resolveAttributesModalRef"
      @submit="handleModalSubmit"
    />
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
            @click="() => toggleStatus(wootConstants.STATUS_TYPE.PENDING)"
          />
        </WootDropdownItem>
      </WootDropdownMenu>
    </div>
  </div>
</template>
