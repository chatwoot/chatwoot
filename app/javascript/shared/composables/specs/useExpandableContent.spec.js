import { nextTick } from 'vue';
import { useExpandableContent } from '../useExpandableContent';

// Mock VueUse composables
vi.mock('@vueuse/core', () => ({
  useToggle: vi.fn(initialValue => {
    let value = initialValue;
    const toggle = newValue => {
      value = newValue !== undefined ? newValue : !value;
    };
    return [{ value }, toggle];
  }),
  useResizeObserver: vi.fn((element, callback) => {
    // Store callback for manual triggering in tests
    if (element.value) {
      callback();
    }
  }),
}));

describe('useExpandableContent', () => {
  let originalGetComputedStyle;

  beforeEach(() => {
    // Mock window.getComputedStyle
    originalGetComputedStyle = window.getComputedStyle;
    window.getComputedStyle = vi.fn(() => ({
      lineHeight: '20px',
    }));
  });

  afterEach(() => {
    window.getComputedStyle = originalGetComputedStyle;
    vi.clearAllMocks();
  });

  it('returns expected properties', () => {
    const result = useExpandableContent();

    expect(result).toHaveProperty('contentElement');
    expect(result).toHaveProperty('isExpanded');
    expect(result).toHaveProperty('needsToggle');
    expect(result).toHaveProperty('toggleExpanded');
    expect(result).toHaveProperty('checkOverflow');
  });

  it('initializes with default values', () => {
    const { isExpanded, needsToggle } = useExpandableContent();

    expect(isExpanded.value).toBe(false);
    expect(needsToggle.value).toBe(false);
  });

  it('checkOverflow sets needsToggle to true when content overflows', async () => {
    const { contentElement, needsToggle, checkOverflow } =
      useExpandableContent();

    // Mock element with overflow
    contentElement.value = {
      scrollHeight: 100, // Much larger than 2 lines (40px)
    };

    checkOverflow();
    await nextTick();

    expect(needsToggle.value).toBe(true);
  });

  it('checkOverflow sets needsToggle to false when content fits', async () => {
    const { contentElement, needsToggle, checkOverflow } =
      useExpandableContent();

    // Mock element without overflow
    contentElement.value = {
      scrollHeight: 30, // Less than 2 lines (40px)
    };

    checkOverflow();
    await nextTick();

    expect(needsToggle.value).toBe(false);
  });

  it('respects custom maxLines option', async () => {
    const { contentElement, needsToggle, checkOverflow } = useExpandableContent(
      {
        maxLines: 3,
      }
    );

    // Mock element that fits in 3 lines but not 2
    contentElement.value = {
      scrollHeight: 50, // Fits in 3 lines (60px) but not 2 lines (40px)
    };

    checkOverflow();
    await nextTick();

    expect(needsToggle.value).toBe(false);
  });

  it('uses defaultLineHeight when computed style is unavailable', async () => {
    window.getComputedStyle = vi.fn(() => ({
      lineHeight: 'normal', // Not a valid number
    }));

    const { contentElement, needsToggle, checkOverflow } = useExpandableContent(
      {
        defaultLineHeight: 16,
      }
    );

    // Mock element that overflows with 16px line height (32px max)
    contentElement.value = {
      scrollHeight: 40,
    };

    checkOverflow();
    await nextTick();

    expect(needsToggle.value).toBe(true);
  });

  it('handles null contentElement gracefully', () => {
    const { checkOverflow } = useExpandableContent();

    // Should not throw when contentElement is null
    expect(() => checkOverflow()).not.toThrow();
  });
});
