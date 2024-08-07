import { useKeyboardEvents } from './useKeyboardEvents';

/**
 * Creates keyboard event handlers for navigation.
 * @param {Function} moveSelectionUp - Function to move selection up.
 * @param {Function} moveSelectionDown - Function to move selection down.
 * @param {Function} [onSelect] - Optional function to handle selection.
 * @returns {Object.<string, {action: Function, allowOnFocusedInput: boolean}>}
 */
const createKeyboardEvents = (moveSelectionUp, moveSelectionDown, onSelect) => {
  const events = {
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
  };

  // Adds an event handler for the Enter key if the onSelect function is provided.
  if (typeof onSelect === 'function') {
    events.Enter = {
      action: e => {
        onSelect();
        e.preventDefault();
      },
      allowOnFocusedInput: true,
    };
  }

  return events;
};

/**
 * A composable for handling keyboard navigation in mention selection scenarios.
 *
 * @param {Object} options - The options for the composable.
 * @param {import('vue').Ref<HTMLElement>} options.elementRef - A ref to the DOM element that will receive keyboard events.
 * @param {import('vue').Ref<Array>} options.items - A ref to the array of selectable items.
 * @param {Function} [options.onSelect] - An optional function to be called when an item is selected.
 * @param {Function} options.adjustScroll - A function to adjust the scroll position after selection changes.
 * @param {import('vue').Ref<number>} options.selectedIndex - A ref to the currently selected index.
 * @returns {{
 *   moveSelectionUp: Function,
 *   moveSelectionDown: Function
 * }} An object containing functions to move the selection up and down.
 */
export function useMentionSelectionKeyboard({
  elementRef,
  items,
  onSelect,
  adjustScroll,
  selectedIndex,
}) {
  /**
   * Moves the selection up in the list of items.
   */
  const moveSelectionUp = () => {
    selectedIndex.value =
      selectedIndex.value === 0
        ? items.value.length - 1
        : selectedIndex.value - 1;
    adjustScroll();
  };

  /**
   * Moves the selection down in the list of items.
   */
  const moveSelectionDown = () => {
    selectedIndex.value =
      selectedIndex.value === items.value.length - 1
        ? 0
        : selectedIndex.value + 1;
    adjustScroll();
  };

  const keyboardEvents = createKeyboardEvents(
    moveSelectionUp,
    moveSelectionDown,
    onSelect
  );

  useKeyboardEvents(keyboardEvents, elementRef);

  return {
    moveSelectionUp,
    moveSelectionDown,
  };
}
