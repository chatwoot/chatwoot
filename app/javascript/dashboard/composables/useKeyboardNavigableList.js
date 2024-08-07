import { useKeyboardEvents } from './useKeyboardEvents';

/**
 * Wrap the action in a function that calls the action and prevents the default event behavior.
 * @param {Function} action - The action to be called.
 * @returns {{action: Function, allowOnFocusedInput: boolean}} An object containing the action and a flag to allow the event on focused input.
 */
const createAction = action => ({
  action: e => {
    action();
    e.preventDefault();
  },
  allowOnFocusedInput: true,
});

/**
 * Creates keyboard event handlers for navigation.
 * @param {Function} moveSelectionUp - Function to move selection up.
 * @param {Function} moveSelectionDown - Function to move selection down.
 * @param {Function} [onSelect] - Optional function to handle selection.
 * @returns {Object.<string, {action: Function, allowOnFocusedInput: boolean}>}
 */
const createKeyboardEvents = (moveSelectionUp, moveSelectionDown, onSelect) => {
  const events = {
    ArrowUp: createAction(moveSelectionUp),
    'Control+KeyP': createAction(moveSelectionUp),
    ArrowDown: createAction(moveSelectionDown),
    'Control+KeyN': createAction(moveSelectionDown),
  };

  // Adds an event handler for the Enter key if the onSelect function is provided.
  if (typeof onSelect === 'function') {
    events.Enter = createAction(onSelect);
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
export function useKeyboardNavigableList({
  elementRef,
  items,
  onSelect,
  adjustScroll,
  selectedIndex,
}) {
  const moveSelectionUp = () => {
    // if the selected index is the first item, move to the last item
    // else move to the previous item
    if (selectedIndex.value === 0) {
      selectedIndex.value = items.value.length - 1;
    } else {
      selectedIndex.value -= 1;
    }
    adjustScroll();
  };

  const moveSelectionDown = () => {
    // if the selected index is the last item, move to the first item
    // else move to the next item
    if (selectedIndex.value === items.value.length - 1) {
      selectedIndex.value = 0;
    } else {
      selectedIndex.value += 1;
    }
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
