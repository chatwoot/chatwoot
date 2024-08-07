import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ref } from 'vue';
import { useKeyboardNavigableList } from '../useKeyboardNavigableList';
import { useKeyboardEvents } from '../useKeyboardEvents';

// Mock the useKeyboardEvents function
vi.mock('../useKeyboardEvents', () => ({
  useKeyboardEvents: vi.fn(),
}));

describe('useKeyboardNavigableList', () => {
  let elementRef;
  let items;
  let onSelect;
  let adjustScroll;
  let selectedIndex;

  const createMockEvent = () => ({ preventDefault: vi.fn() });

  beforeEach(() => {
    elementRef = ref(null);
    items = ref(['item1', 'item2', 'item3']);
    onSelect = vi.fn();
    adjustScroll = vi.fn();
    selectedIndex = ref(0);
    vi.clearAllMocks();
  });

  it('should return moveSelectionUp and moveSelectionDown functions', () => {
    const result = useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });

    expect(result).toHaveProperty('moveSelectionUp');
    expect(result).toHaveProperty('moveSelectionDown');
    expect(typeof result.moveSelectionUp).toBe('function');
    expect(typeof result.moveSelectionDown).toBe('function');
  });

  it('should move selection up correctly', () => {
    const { moveSelectionUp } = useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });

    moveSelectionUp();
    expect(selectedIndex.value).toBe(2);

    moveSelectionUp();
    expect(selectedIndex.value).toBe(1);

    moveSelectionUp();
    expect(selectedIndex.value).toBe(0);

    moveSelectionUp();
    expect(selectedIndex.value).toBe(2);
  });

  it('should move selection down correctly', () => {
    const { moveSelectionDown } = useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });

    moveSelectionDown();
    expect(selectedIndex.value).toBe(1);

    moveSelectionDown();
    expect(selectedIndex.value).toBe(2);

    moveSelectionDown();
    expect(selectedIndex.value).toBe(0);

    moveSelectionDown();
    expect(selectedIndex.value).toBe(1);
  });

  it('should call adjustScroll after moving selection', () => {
    const { moveSelectionUp, moveSelectionDown } = useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });

    moveSelectionUp();
    expect(adjustScroll).toHaveBeenCalledTimes(1);

    moveSelectionDown();
    expect(adjustScroll).toHaveBeenCalledTimes(2);
  });

  it('should include Enter key handler when onSelect is provided', () => {
    useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });

    const keyboardEvents = useKeyboardEvents.mock.calls[0][0];

    expect(keyboardEvents).toHaveProperty('Enter');
    expect(keyboardEvents.Enter.allowOnFocusedInput).toBe(true);
  });

  it('should not include Enter key handler when onSelect is not provided', () => {
    useKeyboardNavigableList({
      elementRef,
      items,
      adjustScroll,
      selectedIndex,
    });

    const keyboardEvents = useKeyboardEvents.mock.calls[0][0];

    expect(keyboardEvents).not.toHaveProperty('Enter');
  });

  it('should not trigger onSelect when items are empty', () => {
    const { moveSelectionUp, moveSelectionDown } = useKeyboardNavigableList({
      elementRef,
      items: ref([]),
      onSelect,
      adjustScroll,
      selectedIndex,
    });

    moveSelectionUp();
    moveSelectionDown();
    expect(onSelect).not.toHaveBeenCalled();
  });

  it('should call useKeyboardEvents with correct parameters', () => {
    useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });

    expect(useKeyboardEvents).toHaveBeenCalledWith(
      expect.any(Object),
      elementRef
    );
  });

  // Keyboard event handlers
  it('should handle ArrowUp key', () => {
    useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });
    const keyboardEvents = useKeyboardEvents.mock.calls[0][0];
    const mockEvent = createMockEvent();
    keyboardEvents.ArrowUp.action(mockEvent);

    expect(selectedIndex.value).toBe(2);
    expect(adjustScroll).toHaveBeenCalled();
    expect(mockEvent.preventDefault).toHaveBeenCalled();
  });

  it('should handle Control+KeyP', () => {
    useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });
    const keyboardEvents = useKeyboardEvents.mock.calls[0][0];
    const mockEvent = createMockEvent();
    keyboardEvents['Control+KeyP'].action(mockEvent);

    expect(selectedIndex.value).toBe(2);
    expect(adjustScroll).toHaveBeenCalled();
    expect(mockEvent.preventDefault).toHaveBeenCalled();
  });

  it('should handle ArrowDown key', () => {
    useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });
    const keyboardEvents = useKeyboardEvents.mock.calls[0][0];
    const mockEvent = createMockEvent();
    keyboardEvents.ArrowDown.action(mockEvent);

    expect(selectedIndex.value).toBe(1);
    expect(adjustScroll).toHaveBeenCalled();
    expect(mockEvent.preventDefault).toHaveBeenCalled();
  });

  it('should handle Control+KeyN', () => {
    useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });
    const keyboardEvents = useKeyboardEvents.mock.calls[0][0];
    const mockEvent = createMockEvent();
    keyboardEvents['Control+KeyN'].action(mockEvent);

    expect(selectedIndex.value).toBe(1);
    expect(adjustScroll).toHaveBeenCalled();
    expect(mockEvent.preventDefault).toHaveBeenCalled();
  });

  it('should handle Enter key when onSelect is provided', () => {
    useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });
    const keyboardEvents = useKeyboardEvents.mock.calls[0][0];
    const mockEvent = createMockEvent();
    keyboardEvents.Enter.action(mockEvent);

    expect(onSelect).toHaveBeenCalled();
    expect(mockEvent.preventDefault).toHaveBeenCalled();
  });

  it('should not have Enter key handler when onSelect is not provided', () => {
    useKeyboardNavigableList({
      elementRef,
      items,
      adjustScroll,
      selectedIndex,
    });

    const keyboardEventsWithoutSelect = useKeyboardEvents.mock.calls[0][0];
    expect(keyboardEventsWithoutSelect).not.toHaveProperty('Enter');
  });

  it('should set allowOnFocusedInput to true for all key handlers', () => {
    useKeyboardNavigableList({
      elementRef,
      items,
      onSelect,
      adjustScroll,
      selectedIndex,
    });
    const keyboardEvents = useKeyboardEvents.mock.calls[0][0];
    const keyHandlers = [
      'ArrowUp',
      'Control+KeyP',
      'ArrowDown',
      'Control+KeyN',
      'Enter',
    ];
    keyHandlers.forEach(key => {
      if (keyboardEvents[key]) {
        expect(keyboardEvents[key].allowOnFocusedInput).toBe(true);
      }
    });
  });
});
