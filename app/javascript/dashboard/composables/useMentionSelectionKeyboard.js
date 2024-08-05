import { ref, onMounted, onBeforeUnmount } from 'vue';
import { useKeyboardEventListener } from './useKeyboardEventListener';

/**
 * Composable for handling keyboard-based mention selection.
 * @param {Object} options - Configuration options.
 * @param {Array} options.items - The list of items to select from.
 * @param {Function} options.onSelect - Callback function when an item is selected.
 * @param {Function} options.adjustScroll - Function to adjust scroll position.
 * @returns {Object} An object containing methods and state for mention selection.
 */
export function useMentionSelectionKeyboard({ items, onSelect, adjustScroll }) {
  const selectedIndex = ref(0);

  const moveSelectionUp = () => {
    if (!selectedIndex.value) {
      selectedIndex.value = items.length - 1;
    } else {
      selectedIndex.value -= 1;
    }
    adjustScroll();
  };

  const moveSelectionDown = () => {
    if (selectedIndex.value === items.length - 1) {
      selectedIndex.value = 0;
    } else {
      selectedIndex.value += 1;
    }
    adjustScroll();
  };

  const getKeyboardEvents = () => ({
    ArrowUp: {
      action: e => {
        moveSelectionUp();
        e.preventDefault();
      },
      allowOnFocusedInput: true,
    },
    'Control+KeyP': {
      action: e => {
        moveSelectionUp();
        e.preventDefault();
      },
      allowOnFocusedInput: true,
    },
    ArrowDown: {
      action: e => {
        moveSelectionDown();
        e.preventDefault();
      },
      allowOnFocusedInput: true,
    },
    'Control+KeyN': {
      action: e => {
        moveSelectionDown();
        e.preventDefault();
      },
      allowOnFocusedInput: true,
    },
    Enter: {
      action: e => {
        onSelect();
        e.preventDefault();
      },
      allowOnFocusedInput: true,
    },
  });

  const { addEventHandler, removeEventHandler } = useKeyboardEventListener();

  onMounted(() => {
    const events = getKeyboardEvents();
    if (events) {
      addEventHandler(events);
    }
  });

  onBeforeUnmount(() => {
    removeEventHandler();
  });

  return {
    selectedIndex,
    moveSelectionUp,
    moveSelectionDown,
  };
}
