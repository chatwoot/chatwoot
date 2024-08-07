import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ref } from 'vue';
import { useMentionSelectionKeyboard } from '../useMentionSelectionKeyboard';
import { useKeyboardEvents } from '../useKeyboardEvents';

// Mock the useKeyboardEvents function
vi.mock('../useKeyboardEvents', () => ({
  useKeyboardEvents: vi.fn(),
}));

describe('useMentionSelectionKeyboard', () => {
  let elementRef;
  let items;
  let onSelect;
  let adjustScroll;
  let selectedIndex;

  beforeEach(() => {
    elementRef = ref(null);
    items = ref(['item1', 'item2', 'item3']);
    onSelect = vi.fn();
    adjustScroll = vi.fn();
    selectedIndex = ref(0);
    vi.clearAllMocks();
  });

  it('should return moveSelectionUp and moveSelectionDown functions', () => {
    const result = useMentionSelectionKeyboard({
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
    const { moveSelectionUp } = useMentionSelectionKeyboard({
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
    const { moveSelectionDown } = useMentionSelectionKeyboard({
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
    const { moveSelectionUp, moveSelectionDown } = useMentionSelectionKeyboard({
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
    useMentionSelectionKeyboard({
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
    useMentionSelectionKeyboard({
      elementRef,
      items,
      adjustScroll,
      selectedIndex,
    });

    const keyboardEvents = useKeyboardEvents.mock.calls[0][0];

    expect(keyboardEvents).not.toHaveProperty('Enter');
  });

  it('should call useKeyboardEvents with correct parameters', () => {
    useMentionSelectionKeyboard({
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
});
