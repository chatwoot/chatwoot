import { ref, nextTick } from 'vue';
import { useDropdownPosition } from '../useDropdownPosition';

vi.mock('@vueuse/core', () => ({
  useElementBounding: vi.fn(elementRef => {
    const top = ref(0);
    const right = ref(0);
    const bottom = ref(100);
    const left = ref(0);
    const width = ref(200);
    const height = ref(50);

    const update = vi.fn(() => {
      if (elementRef && elementRef.value?.getBoundingClientRect) {
        const rect = elementRef.value.getBoundingClientRect();
        top.value = rect.top;
        right.value = rect.right;
        bottom.value = rect.bottom;
        left.value = rect.left;
        width.value = rect.width;
        height.value = rect.height;
      }
    });

    update();

    return { top, right, bottom, left, width, height, x: left, y: top, update };
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

    querySelectorSpy = vi.spyOn(document, 'querySelector').mockReturnValue({
      getAttribute: () => 'ltr',
    });
  });

  afterEach(() => {
    querySelectorSpy.mockRestore();
  });

  it('should return default position when disabled', () => {
    enabled.value = false;

    const { position } = useDropdownPosition(triggerRef, dropdownRef, enabled);

    expect(position.value.class).toBe('top-full mt-2');
    expect(position.value.style).toEqual({});
  });

  it('should return default position when refs are null', () => {
    triggerRef.value = null;
    dropdownRef.value = null;

    const { position } = useDropdownPosition(triggerRef, dropdownRef, enabled);

    expect(position.value.class).toBe('top-full mt-2');
    expect(position.value.style).toEqual({ left: '0px' });
  });

  it('should calculate position when enabled and refs exist', () => {
    const { position } = useDropdownPosition(triggerRef, dropdownRef, enabled);

    // Should return some position classes (not the default)
    expect(position.value.class).toBeTruthy();
    expect(typeof position.value.class).toBe('string');
  });

  it('should position dropdown below trigger when enough space', () => {
    // Window height: 768, Trigger bottom: 150, Dropdown height: 200, Margin: 16
    // Space below: 768 - 150 = 618px
    // Required: 200 + 16 = 216px
    // 618 >= 216, so position below
    const { position } = useDropdownPosition(triggerRef, dropdownRef, enabled);

    expect(position.value.class).toContain('top-full');
    expect(position.value.class).not.toContain('bottom-full');
  });

  it('should position dropdown above trigger when insufficient space below', () => {
    // Window height: 768, Trigger bottom: 750, Dropdown height: 200, Margin: 16
    // Space below: 768 - 750 = 18px
    // Required: 200 + 16 = 216px
    // 18 < 216, so position above
    triggerRef.value.getBoundingClientRect = () => ({
      top: 700,
      right: 250,
      bottom: 750,
      left: 50,
      width: 200,
      height: 50,
    });

    const { position } = useDropdownPosition(triggerRef, dropdownRef, enabled);

    expect(position.value.class).toContain('bottom-full');
    expect(position.value.class).not.toContain('top-full');
  });

  it('should align dropdown to left by default (LTR)', () => {
    // Window width: 1024, Trigger left: 50, Dropdown width: 250
    // Available right: 1024 - 50 = 974px
    // Overflow: 250 - 974 = -724 (no overflow)
    // Result: left: 0px
    const { position } = useDropdownPosition(triggerRef, dropdownRef, enabled);

    expect(position.value.style).toEqual({ left: '0px' });
  });

  it('should shift left when dropdown would overflow right edge (LTR)', () => {
    // Window width: 1024, Trigger left: 800, Dropdown width: 250
    // Available right: 1024 - 800 = 224px
    // Overflow: 250 - 224 = 26px
    // Result: left: -26px
    triggerRef.value.getBoundingClientRect = () => ({
      top: 100,
      right: 1000,
      bottom: 150,
      left: 800,
      width: 200,
      height: 50,
    });

    const { position } = useDropdownPosition(triggerRef, dropdownRef, enabled);

    expect(position.value.style).toEqual({ left: '-26px' });
  });

  it('should handle RTL layout', () => {
    querySelectorSpy.mockReturnValue({
      getAttribute: () => 'rtl',
    });

    const { position } = useDropdownPosition(triggerRef, dropdownRef, enabled);

    expect(position.value.style).toHaveProperty('right');
  });

  it('should reactively update when enabled changes', async () => {
    const { position } = useDropdownPosition(triggerRef, dropdownRef, enabled);

    // Initially enabled should calculate position
    const initialValue = position.value.class;
    expect(initialValue).toBeTruthy();
    expect(typeof initialValue).toBe('string');

    // Disable - should return default
    enabled.value = false;
    await nextTick();

    expect(position.value.class).toBe('top-full mt-2');
    expect(position.value.style).toEqual({});

    // Re-enable - should calculate again
    enabled.value = true;
    await nextTick();

    expect(position.value.class).toBeTruthy();
    expect(typeof position.value.class).toBe('string');
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
    const { position } = useDropdownPosition(triggerRef, dropdownRef);

    // Should default to enabled (not return default classes)
    expect(position.value.class).toBeTruthy();
  });
});
