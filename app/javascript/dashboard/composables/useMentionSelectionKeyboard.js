import { useKeyboardEvents } from './useKeyboardEvents';

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
    if (!selectedIndex.value) {
      selectedIndex.value = items.value.length - 1;
    } else {
      selectedIndex.value -= 1;
    }
    adjustScroll();
  };

  /**
   * Moves the selection down in the list of items.
   */
  const moveSelectionDown = () => {
    if (selectedIndex.value === items.value.length - 1) {
      selectedIndex.value = 0;
    } else {
      selectedIndex.value += 1;
    }
    adjustScroll();
  };

  /**
   * Keyboard event handlers for navigation and selection.
   * @type {Object.<string, {action: Function, allowOnFocusedInput: boolean}>}
   */
  const keyboardEvents = {
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

  // Add Enter key handler only if onSelect is a function
  if (typeof onSelect === 'function') {
    keyboardEvents.Enter = {
      action: e => {
        onSelect();
        e.preventDefault();
      },
      allowOnFocusedInput: true,
    };
  }

  // Set up keyboard event listeners
  useKeyboardEvents(keyboardEvents, elementRef);

  return {
    moveSelectionUp,
    moveSelectionDown,
  };
}
