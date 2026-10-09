import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useRoute, useRouter } from 'vue-router';
import { useConversationRoutePath } from 'dashboard/composables/useConversationRoutePath';
import { isAConversationRoute } from 'dashboard/helper/routeHelpers';
import { frontendURL } from 'dashboard/helper/URLHelper';

export function useChatListKeyboardEvents(listRef) {
  const route = useRoute();
  const router = useRouter();
  const { buildConversationListPath } = useConversationRoutePath();

  const getKeyboardListenerParams = () => {
    const allConversations = listRef.value.querySelectorAll(
      'div.conversations-list div.conversation'
    );
    const activeConversation = listRef.value.querySelector(
      'div.conversations-list div.conversation.active'
    );
    const activeConversationIndex = [...allConversations].indexOf(
      activeConversation
    );
    const lastConversationIndex = allConversations.length - 1;
    return {
      allConversations,
      activeConversation,
      activeConversationIndex,
      lastConversationIndex,
    };
  };

  const handleConversationNavigation = direction => {
    const { allConversations, activeConversationIndex, lastConversationIndex } =
      getKeyboardListenerParams();

    // Determine the new index based on the direction
    const newIndex =
      direction === 'previous'
        ? activeConversationIndex - 1
        : activeConversationIndex + 1;

    // Check if the new index is within the valid range
    if (
      allConversations.length > 0 &&
      newIndex >= 0 &&
      newIndex <= lastConversationIndex
    ) {
      // Click the conversation at the new index
      allConversations[newIndex].click();
    } else if (allConversations.length > 0) {
      // If the new index is out of range, click the first or last conversation based on the direction
      const fallbackIndex =
        direction === 'previous' ? 0 : lastConversationIndex;
      allConversations[fallbackIndex].click();
    }
  };

  const isModalOrPopupOpen = () => {
    const modal = document.querySelector(
      '.modal-mask, .woot-modal, [role="dialog"], [aria-modal="true"], .emoji-dialog'
    );
    const ninjaKeys = document.querySelector('ninja-keys');
    if (ninjaKeys && ninjaKeys.opened) {
      return true;
    }
    return Boolean(modal);
  };

  const handleCloseConversation = () => {
    if (isModalOrPopupOpen()) {
      return;
    }

    if (!isAConversationRoute(route.name, false, true)) {
      return;
    }

    const listPath = buildConversationListPath();
    if (listPath) {
      router.push(frontendURL(listPath));
    }
  };

  const keyboardEvents = {
    'Alt+KeyJ': {
      action: () => handleConversationNavigation('previous'),
      allowOnFocusedInput: true,
    },
    'Alt+KeyK': {
      action: () => handleConversationNavigation('next'),
      allowOnFocusedInput: true,
    },
    Escape: {
      action: handleCloseConversation,
      allowOnFocusedInput: false,
    },
  };

  useKeyboardEvents(keyboardEvents);
}
