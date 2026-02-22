<script setup>
import { provide, useTemplateRef, shallowRef, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useRouter, useRoute } from 'vue-router';
import { Virtualizer } from 'virtua/vue';
import { useInfiniteScroll, useBreakpoints } from '@vueuse/core';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useAlert } from 'dashboard/composables';
import ConversationItem from './ConversationItem.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ConversationResolveAttributesModal from 'dashboard/components-next/ConversationWorkflow/ConversationResolveAttributesModal.vue';
import wootConstants from 'dashboard/constants/globals';
import {
  isOnMentionsView,
  isOnUnattendedView,
} from 'dashboard/store/modules/conversations/helpers/actionHelpers';
import { conversationListPageURL } from 'dashboard/helper/URLHelper';

const props = defineProps({
  items: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
  showEndOfListMessage: { type: Boolean, default: false },
  isContextMenuOpen: { type: Boolean, default: false },
  label: { type: String, default: '' },
  teamId: { type: [String, Number], default: 0 },
  foldersId: { type: [String, Number], default: 0 },
  conversationType: { type: String, default: '' },
  showAssignee: { type: Boolean, default: false },
  isExpandedLayout: { type: Boolean, default: false },
});

const emit = defineEmits(['loadMore']);
const { t } = useI18n();
const store = useStore();
const router = useRouter();
const route = useRoute();

const parentRef = useTemplateRef('parentRef');
const virtualizerRef = shallowRef(null);
const deleteConversationDialogRef = ref(null);
const conversationToDelete = ref(null);
const resolveAttributesModalRef = ref(null);

provide('contextMenuElementTarget', parentRef);

const breakpoints = useBreakpoints({
  lg: wootConstants.LARGE_SCREEN_BREAKPOINT,
});
const isLargeScreen = breakpoints.greaterOrEqual('lg');
provide('isLargeScreen', isLargeScreen);

useInfiniteScroll(
  parentRef,
  () => {
    if (props.isLoading || props.showEndOfListMessage) return;
    emit('loadMore');
  },
  {
    distance: 400,
  }
);

// Keyboard navigation for conversation list
const handleConversationNavigation = direction => {
  if (!parentRef.value || props.items.length === 0) return;

  const activeElement = parentRef.value.querySelector('.active');
  if (!activeElement) {
    // No active conversation, select first one
    const firstWrapper = parentRef.value.querySelector('[data-id]');
    firstWrapper?.firstElementChild?.click();
    return;
  }

  // Find current conversation ID from active element
  const currentWrapper = activeElement.closest('[data-id]');
  const currentId = currentWrapper?.dataset.id;
  if (!currentId) return;

  // Find index in data array
  const currentIndex = props.items.findIndex(
    item => String(item.id) === currentId
  );
  if (currentIndex === -1) return;

  // Calculate target index
  const delta = direction === 'previous' ? -1 : 1;
  const targetIndex = currentIndex + delta;

  // Clamp to valid range
  if (targetIndex < 0 || targetIndex >= props.items.length) return;

  // Find and click target conversation
  const targetId = props.items[targetIndex].id;
  const targetWrapper = parentRef.value.querySelector(
    `[data-id="${targetId}"]`
  );
  targetWrapper?.firstElementChild?.click();
};

useKeyboardEvents({
  'Alt+KeyJ': {
    action: () => handleConversationNavigation('previous'),
    allowOnFocusedInput: true,
  },
  'Alt+KeyK': {
    action: () => handleConversationNavigation('next'),
    allowOnFocusedInput: true,
  },
});

function handleDeleteConversation(conversationId) {
  conversationToDelete.value = conversationId;
  deleteConversationDialogRef.value?.open();
}

function redirectToConversationList() {
  const {
    params: { accountId, inbox_id: inboxId, label, teamId },
    name,
  } = route;

  let conversationType = '';
  if (isOnMentionsView({ route: { name } })) {
    conversationType = 'mention';
  } else if (isOnUnattendedView({ route: { name } })) {
    conversationType = 'unattended';
  }
  router.push(
    conversationListPageURL({
      accountId,
      conversationType: conversationType,
      customViewId: props.foldersId,
      inboxId,
      label,
      teamId,
    })
  );
}

async function deleteConversation() {
  if (!conversationToDelete.value) return;

  try {
    await store.dispatch('deleteConversation', conversationToDelete.value);
    redirectToConversationList();
    deleteConversationDialogRef.value?.close();
    conversationToDelete.value = null;
    useAlert(t('CONVERSATION.SUCCESS_DELETE_CONVERSATION'));
  } catch (error) {
    useAlert(t('CONVERSATION.FAIL_DELETE_CONVERSATION'));
  }
}

function handleShowResolveAttributesModal({
  conversationId,
  snoozedUntil,
  missing,
  currentCustomAttributes,
}) {
  const conversationContext = {
    id: conversationId,
    snoozedUntil,
  };
  resolveAttributesModalRef.value?.open(
    missing,
    currentCustomAttributes,
    conversationContext
  );
}

function toggleConversationStatus(
  conversationId,
  status,
  snoozedUntil,
  customAttributes = null
) {
  const payload = {
    conversationId,
    status,
    snoozedUntil,
  };

  if (customAttributes) {
    payload.customAttributes = customAttributes;
  }

  store.dispatch('toggleStatus', payload).then(() => {
    useAlert(t('CONVERSATION.CHANGE_STATUS'));
  });
}

function handleResolveWithAttributes({ attributes, context }) {
  if (context) {
    const existingConversation = store.getters.getConversationById(context.id);
    const currentCustomAttributes =
      existingConversation?.custom_attributes || {};
    const mergedAttributes = { ...currentCustomAttributes, ...attributes };

    toggleConversationStatus(
      context.id,
      wootConstants.STATUS_TYPE.RESOLVED,
      context.snoozedUntil,
      mergedAttributes
    );
  }
}
</script>

<template>
  <div
    ref="parentRef"
    class="flex-1 w-full h-full touch-pan-y overflow-x-hidden overscroll-contain [-webkit-overflow-scrolling:touch] [contain:strict] [overflow-anchor:none] [will-change:scroll-position] px-2 pt-2"
    :class="isContextMenuOpen ? 'overflow-hidden' : 'overflow-y-auto'"
  >
    <Virtualizer
      ref="virtualizerRef"
      :data="items"
      :scroll-ref="parentRef"
      :item-size="isLargeScreen && isExpandedLayout ? 48 : 76"
      :buffer-size="100"
      item="div"
      class="[&>div]:after:content-[''] [&>div]:after:absolute [&>div]:after:bottom-0 [&>div]:after:left-0 [&>div]:after:right-0 [&>div]:after:h-px [&>div]:after:bg-n-weak [&>div]:after:pointer-events-none [&>div:has(*:hover)]:after:!bg-n-surface-1 [&>div:has(+_*:hover)]:after:!bg-n-surface-1 [&>div:has(.active)]:after:!bg-n-surface-1 [&>div:has(+_*_.active)]:after:!bg-n-surface-1 [&>div:has(.selected)]:after:!bg-n-surface-1 [&>div:has(+_*_.selected)]:after:!bg-n-surface-1"
    >
      <template #default="{ item }">
        <div :key="item.id" :data-id="item.id">
          <ConversationItem
            :source="item"
            :label="label"
            :team-id="teamId"
            :folders-id="foldersId"
            :conversation-type="conversationType"
            :show-assignee="showAssignee"
            :is-expanded-layout="isExpandedLayout"
            @delete-conversation="handleDeleteConversation"
            @show-resolve-attributes-modal="handleShowResolveAttributesModal"
            @redirect-to-list="redirectToConversationList"
          />
        </div>
      </template>
    </Virtualizer>

    <Dialog
      ref="deleteConversationDialogRef"
      type="alert"
      :title="
        $t('CONVERSATION.DELETE_CONVERSATION.TITLE', {
          conversationId: conversationToDelete,
        })
      "
      :description="$t('CONVERSATION.DELETE_CONVERSATION.DESCRIPTION')"
      :confirm-button-label="$t('CONVERSATION.DELETE_CONVERSATION.CONFIRM')"
      @confirm="deleteConversation"
    />

    <ConversationResolveAttributesModal
      ref="resolveAttributesModalRef"
      @submit="handleResolveWithAttributes"
    />

    <div class="py-2">
      <div v-if="isLoading" class="flex justify-center my-4">
        <Spinner class="text-n-brand" />
      </div>
      <p
        v-else-if="showEndOfListMessage"
        class="p-4 text-center text-sm text-n-slate-10 whitespace-nowrap"
      >
        <Icon
          icon="i-woot-party"
          class="size-4 inline-block align-middle ltr:mr-2 rtl:ml-2"
        />
        <span class="align-middle">
          {{ t('CHAT_LIST.EOF') }}
        </span>
      </p>
    </div>
  </div>
</template>
