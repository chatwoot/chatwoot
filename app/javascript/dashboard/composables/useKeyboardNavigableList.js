/**
 * This composable provides keyboard navigation functionality for list-like UI components
 * such as dropdowns, autocomplete suggestions, or any list of selectable items.
 *
 * TODO - Things that can be improved in the future
 * - The scrolling should be handled by the component instead of the consumer of this composable
 *   it can be done if we know the item height.
 * - The focus should be trapped within the list.
 * - onSelect should be callback instead of a function that is passed
 */
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
 * @param {import('vue').Ref<Array>} items - A ref to the array of selectable items.
 * @returns {Object.<string, {action: Function, allowOnFocusedInput: boolean}>}
 */
const createKeyboardEvents = (
  moveSelectionUp,
  moveSelectionDown,
  onSelect,
  items
) => {
  const events = {
    ArrowUp: createAction(moveSelectionUp),
    'Control+KeyP': createAction(moveSelectionUp),
    ArrowDown: createAction(moveSelectionDown),
    'Control+KeyN': createAction(moveSelectionDown),
  };

  // Adds an event handler for the Enter key if the onSelect function is provided.
  if (typeof onSelect === 'function') {
    events.Enter = createAction(() => items.value?.length > 0 && onSelect());
  }

  return events;
};

/**
 * Updates the selection index based on the current index, total number of items, and direction of movement.
 *
 * @param {number} currentIndex - The current index of the selected item.
 * @param {number} itemsLength - The total number of items in the list.
 * @param {string} direction - The direction of movement, either 'up' or 'down'.
 * @returns {number} The new index after moving in the specified direction.
 */
const updateSelectionIndex = (currentIndex, itemsLength, direction) => {
  // If the selected index is the first item, move to the last item
  // If the selected index is the last item, move to the first item
  if (direction === 'up') {
    return currentIndex === 0 ? itemsLength - 1 : currentIndex - 1;
  }
  return currentIndex === itemsLength - 1 ? 0 : currentIndex + 1;
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
  items,
  onSelect,
  adjustScroll,
  selectedIndex,
}) {
  const moveSelection = direction => {
    selectedIndex.value = updateSelectionIndex(
      selectedIndex.value,
      items.value.length,
      direction
    );
    adjustScroll();
  };

  const moveSelectionUp = () => moveSelection('up');
  const moveSelectionDown = () => moveSelection('down');

  const keyboardEvents = createKeyboardEvents(
    moveSelectionUp,
    moveSelectionDown,
    onSelect,
    items
  );

  useKeyboardEvents(keyboardEvents);

  return {
    moveSelectionUp,
    moveSelectionDown,
  };
}
