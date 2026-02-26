import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

export function useChatListKeyboardEvents(listRef) {
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
  const keyboardEvents = {
    'Alt+KeyJ': {
      action: () => handleConversationNavigation('previous'),
      allowOnFocusedInput: true,
    },
    'Alt+KeyK': {
      action: () => handleConversationNavigation('next'),
      allowOnFocusedInput: true,
    },
  };

  useKeyboardEvents(keyboardEvents);
}
