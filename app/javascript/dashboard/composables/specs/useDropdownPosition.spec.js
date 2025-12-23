import { ref, nextTick } from 'vue';
import { useDropdownPosition } from '../useDropdownPosition';

// Mock VueUse composables
vi.mock('@vueuse/core', () => ({
  useElementBounding: vi.fn(elementRef => {
    // Create reactive refs that update based on element
    const top = ref(0);
    const right = ref(0);
    const bottom = ref(100);
    const left = ref(0);
    const width = ref(200);
    const height = ref(50);

    const update = vi.fn(() => {
      // Update bounds from element when called
      if (elementRef.value?.getBoundingClientRect) {
        const rect = elementRef.value.getBoundingClientRect();
        top.value = rect.top;
        right.value = rect.right;
        bottom.value = rect.bottom;
        left.value = rect.left;
        width.value = rect.width;
        height.value = rect.height;
      }
    });

    // Initial update
    update();

    return {
      top,
      right,
      bottom,
      left,
      width,
      height,
      x: left,
      y: top,
      update,
    };
  }),
  useWindowSize: vi.fn(() => ({
    width: ref(1024),
    height: ref(768),
  })),
}));

describe('useDropdownPosition', () => {
  let triggerRef;
  let dropdownRef;
  let enabled;
  let querySelectorSpy;

  beforeEach(() => {
    // Create mock DOM elements
    triggerRef = ref({
      getBoundingClientRect: () => ({
        top: 100,
        right: 250,
        bottom: 150,
        left: 50,
        width: 200,
        height: 50,
      }),
    });

    dropdownRef = ref({
      getBoundingClientRect: () => ({
        top: 0,
        right: 0,
        bottom: 0,
        left: 0,
        width: 250,
        height: 200,
      }),
    });

    enabled = ref(true);

    // Spy on document.querySelector for RTL check
    querySelectorSpy = vi.spyOn(document, 'querySelector').mockReturnValue({
      getAttribute: () => 'ltr',
    });
  });

  afterEach(() => {
    querySelectorSpy.mockRestore();
  });

  it('should return default position classes when disabled', () => {
    enabled.value = false;

    const { positionClasses } = useDropdownPosition(
      triggerRef,
      dropdownRef,
      enabled
    );

    expect(positionClasses.value).toBe('top-full mt-2 ltr:left-0 rtl:right-0');
  });

  it('should return default position classes when refs are null', () => {
    triggerRef.value = null;
    dropdownRef.value = null;

    const { positionClasses } = useDropdownPosition(
      triggerRef,
      dropdownRef,
      enabled
    );

    expect(positionClasses.value).toBe('top-full mt-2 ltr:left-0 rtl:right-0');
  });

  it('should calculate position when enabled and refs exist', () => {
    const { positionClasses } = useDropdownPosition(
      triggerRef,
      dropdownRef,
      enabled
    );

    // Should return some position classes (not the default)
    expect(positionClasses.value).toBeTruthy();
    expect(typeof positionClasses.value).toBe('string');
  });

  it('should position dropdown below trigger when enough space', () => {
    // Trigger at top of screen, plenty of space below
    // Window height: 768, Trigger bottom: 150
    // Space below: 768 - 150 = 618px
    // Dropdown height: 200px + SAFE_MARGIN (16px) = 216px
    // 618 > 216 = true, so should position below (top-full)
    triggerRef.value.getBoundingClientRect = () => ({
      top: 100,
      right: 250,
      bottom: 150,
      left: 50,
      width: 200,
      height: 50,
    });

    const { positionClasses } = useDropdownPosition(
      triggerRef,
      dropdownRef,
      enabled
    );

    expect(positionClasses.value).toContain('top-full');
    expect(positionClasses.value).not.toContain('bottom-full');
  });

  it('should position dropdown above trigger when insufficient space below', () => {
    // Trigger near bottom of screen
    // Window height: 768, Trigger bottom: 750
    // Space below: 768 - 750 = 18px
    // Dropdown height: 200px + SAFE_MARGIN (16px) = 216px
    // 18 < 216 = true, so should position above (bottom-full)
    triggerRef.value.getBoundingClientRect = () => ({
      top: 700,
      right: 250,
      bottom: 750,
      left: 50,
      width: 200,
      height: 50,
    });

    const { positionClasses } = useDropdownPosition(
      triggerRef,
      dropdownRef,
      enabled
    );

    expect(positionClasses.value).toContain('bottom-full');
    expect(positionClasses.value).not.toContain('top-full');
  });

  it('should align dropdown to left by default (LTR)', () => {
    // LTR layout, trigger at left: 50
    // Window width: 1024, Dropdown width: 250
    // Trigger left: 50, Dropdown width: 250, SAFE_MARGIN: 16
    // Would overflow: 50 + 250 + 16 = 316 < 1024 = false
    // So should align left (ltr:left-0)
    querySelectorSpy.mockReturnValue({
      getAttribute: () => 'ltr',
    });

    const { positionClasses } = useDropdownPosition(
      triggerRef,
      dropdownRef,
      enabled
    );

    expect(positionClasses.value).toContain('ltr:left-0');
    expect(positionClasses.value).not.toContain('ltr:right-0');
  });

  it('should align dropdown to right when would overflow (LTR)', () => {
    // Trigger near right edge
    // Window width: 1024, Dropdown width: 250
    // Trigger left: 800, Dropdown width: 250, SAFE_MARGIN: 16
    // Would overflow: 800 + 250 + 16 = 1066 > 1024 = true
    // So should align right (ltr:right-0)
    triggerRef.value.getBoundingClientRect = () => ({
      top: 100,
      right: 1000,
      bottom: 150,
      left: 800,
      width: 200,
      height: 50,
    });

    const { positionClasses } = useDropdownPosition(
      triggerRef,
      dropdownRef,
      enabled
    );

    expect(positionClasses.value).toContain('ltr:right-0');
    expect(positionClasses.value).not.toContain('ltr:left-0');
  });

  it('should handle RTL layout', () => {
    querySelectorSpy.mockReturnValue({
      getAttribute: () => 'rtl',
    });

    const { positionClasses } = useDropdownPosition(
      triggerRef,
      dropdownRef,
      enabled
    );

    expect(positionClasses.value).toContain('rtl:');
  });

  it('should reactively update when enabled changes', async () => {
    const { positionClasses } = useDropdownPosition(
      triggerRef,
      dropdownRef,
      enabled
    );

    // Initially enabled should calculate position
    const initialValue = positionClasses.value;
    expect(initialValue).toBeTruthy();
    expect(typeof initialValue).toBe('string');

    // Disable - should return default
    enabled.value = false;
    await nextTick();

    expect(positionClasses.value).toBe('top-full mt-2 ltr:left-0 rtl:right-0');

    // Re-enable - should calculate again
    enabled.value = true;
    await nextTick();

    expect(positionClasses.value).toBeTruthy();
    expect(typeof positionClasses.value).toBe('string');
  });

  it('should provide updatePosition function', () => {
    const { updatePosition } = useDropdownPosition(
      triggerRef,
      dropdownRef,
      enabled
    );

    expect(updatePosition).toBeDefined();
    expect(typeof updatePosition).toBe('function');

    // Should not throw when called
    expect(() => updatePosition()).not.toThrow();
  });

  it('should handle optional enabled parameter', () => {
    // Should work without enabled parameter (backward compatibility)
    const { positionClasses } = useDropdownPosition(triggerRef, dropdownRef);

    // Should default to enabled (not return default classes)
    expect(positionClasses.value).toBeTruthy();
  });
});
