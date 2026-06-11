<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useWindowSize } from '@vueuse/core';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useHaptics } from 'dashboard/composables/useHaptics';
import { useSwipeBack } from 'dashboard/composables/useSwipeBack';
import { useKeyboardResize } from 'dashboard/composables/useKeyboardResize';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';

import MobileChatHeader from './MobileChatHeader.vue';
import MobileConversationActionsView from './MobileConversationActionsView.vue';
import MobileContactDetailsView from './MobileContactDetailsView.vue';
import MobileReplyBox from './MobileReplyBox.vue';
import MessagesView from 'dashboard/components/widgets/conversation/MessagesView.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  conversationId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['back', 'swipeProgress', 'swipeEnd']);
const store = useStore();
const route = useRoute();
const router = useRouter();
const { width: windowWidth } = useWindowSize();
const { light, medium } = useHaptics();

const chatRootRef = ref(null);
const { swipeOffset, isSwiping, swipeProgress } = useSwipeBack(
  chatRootRef,
  () => emit('back')
);
const { keyboardHeight, isKeyboardOpen } = useKeyboardResize();

// Liquid Glass swipe-back styles
const swipeBackStyle = computed(() => {
  const style = {};
  if (isKeyboardOpen.value) {
    style.paddingBottom = `${keyboardHeight.value}px`;
  }
  if (swipeOffset.value <= 0) return style;
  const progress = swipeProgress.value;
  style.transform = `translateX(${swipeOffset.value}px) scale(${1 - progress * 0.04})`;
  style.borderRadius = `${progress * 20}px`;
  style.boxShadow = `-8px 0 30px rgba(0, 0, 0, ${progress * 0.15})`;
  style.overflow = 'hidden';
  return style;
});

const glassEdgeStyle = computed(() => ({
  opacity: swipeProgress.value * 0.7,
  transform: `translateX(${swipeOffset.value - 14}px)`,
}));

watch(swipeProgress, val => {
  if (val > 0) {
    emit('swipeProgress', val);
  } else {
    emit('swipeEnd');
  }
});

const activePanel = ref(0);
const panelDragOffset = ref(0);
const isPanelDragging = ref(false);

let panelTouchStartX = 0;
let panelTouchStartY = 0;
let panelTracking = false;
let panelDirectionLocked = false;
let panelIsHorizontal = false;
let panelThresholdReached = false;

const currentChat = useMapGetter('getSelectedChat');
const allConversations = useMapGetter('getAllConversations');

const chatLoaded = computed(() => {
  return currentChat.value && currentChat.value.id === props.conversationId;
});

const { accountScopedRoute } = useAccount();

const showContactDetails = ref(false);
const contactDetailsId = ref(null);

const onOpenContact = contactId => {
  contactDetailsId.value = contactId;
  showContactDetails.value = true;
};

const closeContactDetails = () => {
  showContactDetails.value = false;
};

const onOpenContactConversation = conversationId => {
  closeContactDetails();
  if (conversationId === props.conversationId) return;
  router.push(
    accountScopedRoute('inbox_conversation', {
      conversation_id: conversationId,
    })
  );
};

const contactName = computed(() => {
  if (!chatLoaded.value) return '';
  const contact = currentChat.value.meta?.sender;
  return contact?.name || contact?.email || `#${props.conversationId}`;
});

const contactAvatar = computed(() => {
  if (!chatLoaded.value) return '';
  return currentChat.value.meta?.sender?.thumbnail || '';
});

const inboxId = computed(() => {
  return currentChat.value?.inbox_id || '';
});

const panelWidth = computed(() => Math.max(windowWidth.value || 0, 1));

const panelProgress = computed(() => {
  const dragRatio = Math.min(
    Math.abs(panelDragOffset.value) / panelWidth.value,
    1
  );
  if (activePanel.value === 1) {
    return Math.max(0, 1 - dragRatio);
  }

  return dragRatio;
});

const actionsPageVisible = computed(() => {
  return activePanel.value === 1 || isPanelDragging.value;
});

const messagePanelStyle = computed(() => {
  const progress = panelProgress.value;
  const scale = 1 - progress * 0.035;
  const translateX = progress * 8;
  const borderRadius = `${progress * 24}px`;
  const boxShadow = `0 18px 40px rgba(15, 23, 42, ${0.08 + progress * 0.12})`;

  return {
    transform: `translateX(${translateX}px) scale(${scale})`,
    borderRadius,
    boxShadow,
  };
});

const actionsPanelStyle = computed(() => {
  const progress = panelProgress.value;
  const translateX = (1 - progress) * 42;
  const opacity = 0.45 + progress * 0.55;

  return {
    transform: `translateX(${translateX}px)`,
    opacity,
  };
});

const pagerBackdropStyle = computed(() => ({
  opacity: panelProgress.value * 0.08,
}));

const hintPillStyle = computed(() => ({
  opacity: activePanel.value === 0 ? 0.8 - panelProgress.value * 0.7 : 0,
  transform: `translateX(${panelProgress.value * 8}px)`,
}));

const pagerTranslateX = computed(() => {
  return `translateX(${-activePanel.value * panelWidth.value + panelDragOffset.value}px)`;
});

const openActionsPanel = ({ withHaptic = true } = {}) => {
  if (activePanel.value === 1) return;

  activePanel.value = 1;
  panelDragOffset.value = 0;
  panelThresholdReached = false;

  if (withHaptic) light();
};

const closeActionsPanel = () => {
  activePanel.value = 0;
  panelDragOffset.value = 0;
  panelThresholdReached = false;
};

const setActiveChat = async () => {
  const conversationId = props.conversationId;
  const chat = allConversations.value.find(c => c.id === conversationId);
  if (chat) {
    store.dispatch('setActiveChat', { data: chat });
  } else {
    await store.dispatch('getConversation', conversationId);
    const fetchedChat = store.getters.getAllConversations.find(
      c => c.id === conversationId
    );
    if (fetchedChat) {
      store.dispatch('setActiveChat', { data: fetchedChat });
    }
  }
};

const refreshConversation = async () => {
  await store.dispatch('getConversation', props.conversationId);
  await setActiveChat();
  store.dispatch('conversationLabels/get', props.conversationId);
  store.dispatch('conversationWatchers/show', {
    conversationId: props.conversationId,
  });
};

const onPanelTouchStart = event => {
  const touch = event.touches[0];
  panelTouchStartX = touch.clientX;
  panelTouchStartY = touch.clientY;
  panelTracking = true;
  panelDirectionLocked = false;
  panelIsHorizontal = false;
  panelThresholdReached = false;
};

const onPanelTouchMove = event => {
  if (!panelTracking) return;

  const touch = event.touches[0];
  const deltaX = touch.clientX - panelTouchStartX;
  const deltaY = touch.clientY - panelTouchStartY;

  if (!panelDirectionLocked) {
    if (Math.abs(deltaX) > 10 || Math.abs(deltaY) > 10) {
      panelDirectionLocked = true;
      panelIsHorizontal = Math.abs(deltaX) > Math.abs(deltaY) * 1.2;
    }

    if (!panelDirectionLocked) return;
  }

  if (!panelIsHorizontal) {
    panelTracking = false;
    return;
  }

  if (activePanel.value === 0 && deltaX < 0) {
    isPanelDragging.value = true;
    panelDragOffset.value = Math.max(deltaX, -windowWidth.value * 0.45);
  } else if (activePanel.value === 1 && deltaX > 0) {
    isPanelDragging.value = true;
    panelDragOffset.value = Math.min(deltaX, windowWidth.value * 0.45);
  }

  if (Math.abs(panelDragOffset.value) > 72 && !panelThresholdReached) {
    panelThresholdReached = true;
    medium();
  } else if (Math.abs(panelDragOffset.value) <= 72) {
    panelThresholdReached = false;
  }
};

const onPanelTouchEnd = () => {
  if (!panelTracking || !panelIsHorizontal) {
    panelTracking = false;
    panelDragOffset.value = 0;
    isPanelDragging.value = false;
    panelThresholdReached = false;
    return;
  }

  const shouldOpen =
    activePanel.value === 0 && Math.abs(panelDragOffset.value) > 72;
  const shouldClose = activePanel.value === 1 && panelDragOffset.value > 72;

  if (shouldOpen) {
    openActionsPanel();
  } else if (shouldClose) {
    closeActionsPanel();
  } else {
    panelDragOffset.value = 0;
  }

  panelTracking = false;
  isPanelDragging.value = false;
  panelThresholdReached = false;
};

const onPanelTouchCancel = () => {
  panelTracking = false;
  panelDirectionLocked = false;
  panelIsHorizontal = false;
  panelDragOffset.value = 0;
  isPanelDragging.value = false;
  panelThresholdReached = false;
};

const consumeFocusReplyParam = () => {
  if (!route?.query) return;
  const focusReply = route.query.focus_reply;
  if (!focusReply || focusReply === '0') return;

  // Clear the query so a refresh does not re-focus the input.
  router
    .replace({
      query: { ...route.query, focus_reply: undefined },
    })
    .catch(() => {});

  emitter.emit(BUS_EVENTS.FOCUS_REPLY_BOX, {
    conversationId: props.conversationId,
  });
};

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('teams/get');
  store.dispatch('inboxes/get');
  store.dispatch('labels/get');
  store.dispatch('conversationLabels/get', props.conversationId);
  store.dispatch('conversationWatchers/show', {
    conversationId: props.conversationId,
  });
  setActiveChat().then(() => consumeFocusReplyParam());
});

watch(
  () => props.conversationId,
  () => {
    closeActionsPanel();
    closeContactDetails();
    setActiveChat().then(() => consumeFocusReplyParam());
  }
);
</script>

<template>
  <div
    ref="chatRootRef"
    class="relative flex flex-col w-full h-full bg-n-surface-1"
    :class="{
      'transition-all duration-[250ms] ease-[cubic-bezier(0.25,0.46,0.45,0.94)]':
        !isSwiping && swipeOffset > 0,
    }"
    :style="swipeBackStyle"
  >
    <!-- Liquid Glass edge indicator -->
    <div
      v-if="isSwiping"
      class="fixed top-0 bottom-0 left-0 z-50 w-[4px] pointer-events-none bg-gradient-to-r from-white/50 via-white/20 to-transparent dark:from-white/25 dark:via-white/10"
      :style="glassEdgeStyle"
    />

    <MobileChatHeader
      :name="contactName"
      :avatar="contactAvatar"
      :status="currentChat?.status || 'open'"
      @back="emit('back')"
      @refresh="refreshConversation"
      @open-actions="openActionsPanel"
    />
    <div
      class="relative flex flex-1 min-h-0 overflow-hidden bg-[radial-gradient(circle_at_top_right,_rgba(59,130,246,0.08),_transparent_42%),linear-gradient(180deg,#f8fafc_0%,#eef2f7_100%)]"
      @touchstart.passive="onPanelTouchStart"
      @touchmove.passive="onPanelTouchMove"
      @touchend="onPanelTouchEnd"
      @touchcancel="onPanelTouchCancel"
    >
      <div
        class="pointer-events-none absolute inset-0 z-0 bg-slate-950 transition-opacity duration-300"
        :style="pagerBackdropStyle"
      />

      <div
        class="pointer-events-none absolute right-3 top-3 z-20 rounded-full bg-white/80 px-2.5 py-1 shadow-sm backdrop-blur"
        :class="{ 'transition-all duration-300': !isPanelDragging }"
        :style="hintPillStyle"
      >
        <div
          class="flex items-center gap-1.5 text-[11px] font-medium text-n-slate-10"
        >
          <span class="i-lucide-arrow-left size-3.5" />
          <span>{{ $t('MOBILE.ACTIONS.CTA.SWIPE_HINT') }}</span>
        </div>
      </div>

      <div
        class="relative z-10 flex h-full w-full"
        :class="{
          'transition-transform duration-300 ease-out': !isPanelDragging,
        }"
        :style="{ transform: pagerTranslateX }"
      >
        <div
          class="mobile-chat-messages flex w-full min-w-0 shrink-0 flex-col overflow-hidden bg-n-surface-1"
          :class="{ 'transition-all duration-300 ease-out': !isPanelDragging }"
          :style="messagePanelStyle"
        >
          <div class="flex min-h-0 w-full flex-1 min-w-0">
            <MessagesView
              v-if="chatLoaded"
              :inbox-id="inboxId"
              :is-inbox-view="false"
            />
            <div v-else class="flex h-full w-full items-center justify-center">
              <Spinner class="text-n-brand" />
            </div>
          </div>
          <MobileReplyBox v-if="chatLoaded" />
        </div>

        <div
          class="w-full min-w-0 shrink-0 overflow-y-auto bg-transparent pl-3 pr-2"
          :class="{
            'pointer-events-none': !actionsPageVisible,
            'transition-all duration-300 ease-out': !isPanelDragging,
          }"
          :style="actionsPanelStyle"
        >
          <MobileConversationActionsView
            v-if="chatLoaded"
            :conversation-id="conversationId"
            @open-contact="onOpenContact"
          />
        </div>
      </div>
    </div>

    <!-- Contact details (slide-in page over the chat) -->
    <Transition
      enter-active-class="transition-transform duration-300 ease-out"
      enter-from-class="translate-x-full"
      enter-to-class="translate-x-0"
      leave-active-class="transition-transform duration-200 ease-in"
      leave-from-class="translate-x-0"
      leave-to-class="translate-x-full"
    >
      <MobileContactDetailsView
        v-if="showContactDetails && contactDetailsId"
        :contact-id="contactDetailsId"
        class="absolute inset-0 z-30"
        @back="closeContactDetails"
        @open-conversation="onOpenContactConversation"
      />
    </Transition>
  </div>
</template>

<style scoped>
/* Hide desktop ReplyBox inside MessagesView — MobileReplyBox replaces it */
.mobile-chat-messages :deep(.reply-box),
.mobile-chat-messages :deep(.reply-box__top),
.mobile-chat-messages :deep(.reply-editor-wrap) {
  display: none !important;
}

.mobile-chat-messages {
  --mobile-bubble-max-width: min(300px, calc(100vw - 4.5rem));
}

.mobile-chat-messages :deep(.message-bubble-container) {
  margin-bottom: 4px;
}

.mobile-chat-messages :deep(.left-bubble),
.mobile-chat-messages :deep(.right-bubble) {
  max-width: var(--mobile-bubble-max-width) !important;
}

.mobile-chat-messages :deep(.whatsapp-interactive-bubble),
.mobile-chat-messages :deep(.rich-cards-container),
.mobile-chat-messages :deep(.max-w-80),
.mobile-chat-messages :deep(.max-w-sm) {
  max-width: 100% !important;
}

.mobile-chat-messages :deep(.whatsapp-interactive-bubble),
.mobile-chat-messages :deep(.rich-cards-bubble),
.mobile-chat-messages :deep([data-bubble-name='text']),
.mobile-chat-messages :deep([data-bubble-name='attachment']),
.mobile-chat-messages :deep([data-bubble-name='unsupported']) {
  width: fit-content;
  max-width: var(--mobile-bubble-max-width) !important;
}

.mobile-chat-messages :deep(.prose-bubble),
.mobile-chat-messages :deep(.whatsapp-button),
.mobile-chat-messages :deep(.card-title),
.mobile-chat-messages :deep(.card-description) {
  overflow-wrap: anywhere;
  word-break: break-word;
}

.mobile-chat-messages :deep(.whatsapp-header img),
.mobile-chat-messages :deep(.rich-cards-container img) {
  max-width: 100%;
}
</style>
