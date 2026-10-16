import { ref } from 'vue';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';

// Mock @vueuse/core — return reactive refs we can control per test
const mockBounding = () => ({
  top: ref(0),
  bottom: ref(0),
  left: ref(0),
  right: ref(0),
  width: ref(0),
  height: ref(0),
  update: vi.fn(),
});

const triggerBounds = mockBounding();
const dropdownBounds = mockBounding();
const winWidth = ref(1024);
const winHeight = ref(768);

vi.mock('@vueuse/core', () => {
  let callCount = 0;
  return {
    // First call = trigger, second = dropdown, third = container (if any)
    useElementBounding: () => {
      callCount += 1;
      return callCount % 3 === 1 ? triggerBounds : dropdownBounds;
    },
    useWindowSize: () => ({ width: winWidth, height: winHeight }),
  };
});

const setTrigger = ({ top, bottom, left, right }) => {
  triggerBounds.top.value = top;
  triggerBounds.bottom.value = bottom;
  triggerBounds.left.value = left ?? 100;
  triggerBounds.right.value = right ?? 200;
};

const setDropdown = ({ width, height }) => {
  dropdownBounds.width.value = width ?? 200;
  dropdownBounds.height.value = height;
};

describe('useDropdownPosition', () => {
  beforeEach(() => {
    winWidth.value = 1024;
    winHeight.value = 768;
    document.body.innerHTML = '<div id="app" dir="ltr"></div>';
  });

  describe('verticalClass (relative mode)', () => {
    it('places below when enough space', () => {
      // Trigger at y=100, dropdown 200px tall
      // Space below = 768 - 140 = 628 → fits (628 > 216)
      setTrigger({ top: 100, bottom: 140 });
      setDropdown({ height: 200 });

      const { position } = useDropdownPosition(ref(null), ref(null), ref(true));
      expect(position.value.class).toBe('top-full mt-2');
    });

    it('places above when not enough space below but enough above', () => {
      // Trigger near bottom at y=600
      // Space below = 128 → doesn't fit. Space above = 600 → fits
      setTrigger({ top: 600, bottom: 640 });
      setDropdown({ height: 200 });

      const { position } = useDropdownPosition(ref(null), ref(null), ref(true));
      expect(position.value.class).toBe('bottom-full mb-2');
    });

    it('picks the side with more space when dropdown fits neither', () => {
      // Dropdown 500px tall, won't fit above (300) or below (428)
      // Below has more room → stays below
      setTrigger({ top: 300, bottom: 340 });
      setDropdown({ height: 500 });

      const { position } = useDropdownPosition(ref(null), ref(null), ref(true));
      expect(position.value.class).toBe('top-full mt-2');
    });

    it('picks above when above has more space and neither fits', () => {
      // Dropdown 600px tall, won't fit above (500) or below (228)
      // Above has more room → flips above
      setTrigger({ top: 500, bottom: 540 });
      setDropdown({ height: 600 });

      const { position } = useDropdownPosition(ref(null), ref(null), ref(true));
      expect(position.value.class).toBe('bottom-full mb-2');
    });

    it('returns default when disabled', () => {
      setTrigger({ top: 700, bottom: 740 });
      setDropdown({ height: 200 });

      const { position } = useDropdownPosition(
        ref(null),
        ref(null),
        ref(false)
      );
      expect(position.value.class).toBe('top-full mt-2');
      expect(position.value.style).toEqual({});
    });
  });

  describe('fixedPosition', () => {
    it('places below with correct top and maxHeight', () => {
      // Trigger at y=140, space below = 628
      // top = 140 + 8(gap) = 148
      // maxHeight = 628 - 8(gap) - 16(margin) = 604
      setTrigger({ top: 100, bottom: 140 });
      setDropdown({ height: 200, width: 200 });

      const { fixedPosition } = useDropdownPosition(
        ref(null),
        ref(null),
        ref(true)
      );

      expect(fixedPosition.value.style.top).toBe('148px');
      expect(fixedPosition.value.style.bottom).toBeUndefined();
      expect(fixedPosition.value.style.maxHeight).toBe('604px');
    });

    it('flips above with correct bottom and maxHeight', () => {
      // Trigger near bottom at y=650, space below = 78 → doesn't fit
      // Flips above: bottom = 768 - 650 + 8 = 126
      // maxHeight = 650 - 8 - 16 = 626
      setTrigger({ top: 650, bottom: 690 });
      setDropdown({ height: 200, width: 200 });

      const { fixedPosition } = useDropdownPosition(
        ref(null),
        ref(null),
        ref(true)
      );

      expect(fixedPosition.value.style.bottom).toBe('126px');
      expect(fixedPosition.value.style.top).toBeUndefined();
      expect(fixedPosition.value.style.maxHeight).toBe('626px');
    });

    it('constrains maxHeight to available space on short viewports', () => {
      // Short viewport (400px), trigger in the middle, dropdown 500px tall
      // Neither side fits → above (200) > below (160) → places above
      // maxHeight capped to 200 - 8 - 16 = 176
      winHeight.value = 400;
      setTrigger({ top: 200, bottom: 240 });
      setDropdown({ height: 500, width: 200 });

      const { fixedPosition } = useDropdownPosition(
        ref(null),
        ref(null),
        ref(true)
      );

      expect(fixedPosition.value.style.bottom).toBeDefined();
      expect(fixedPosition.value.style.maxHeight).toBe('176px');
    });

    it('returns defaults when disabled', () => {
      const { fixedPosition } = useDropdownPosition(
        ref(null),
        ref(null),
        ref(false)
      );
      expect(fixedPosition.value.class).toBe('fixed z-[9999]');
      expect(fixedPosition.value.style).toEqual({});
    });
  });

  describe('horizontal positioning (fixedPosition)', () => {
    it('anchors to the right edge by default (align=end, LTR)', () => {
      // align=end + LTR → anchorLeft=false → uses style.right
      // right = 1024 - 900 = 124
      setTrigger({ top: 100, bottom: 140, left: 800, right: 900 });
      setDropdown({ height: 100, width: 200 });

      const { fixedPosition } = useDropdownPosition(
        ref(null),
        ref(null),
        ref(true)
      );

      expect(fixedPosition.value.style.right).toBe('124px');
    });

    it('anchors to the left edge when align=start (LTR)', () => {
      // align=start + LTR → anchorLeft=true → uses style.left
      setTrigger({ top: 100, bottom: 140, left: 100, right: 200 });
      setDropdown({ height: 100, width: 200 });

      const { fixedPosition } = useDropdownPosition(
        ref(null),
        ref(null),
        ref(true),
        { align: 'start' }
      );

      expect(fixedPosition.value.style.left).toBe('100px');
    });

    it('shifts left when dropdown overflows right edge', () => {
      // Trigger at x=900, dropdown 300px wide → 900+300=1200 > 1024
      // Falls back to right: 16px (margin)
      setTrigger({ top: 100, bottom: 140, left: 900, right: 1000 });
      setDropdown({ height: 100, width: 300 });

      const { fixedPosition } = useDropdownPosition(
        ref(null),
        ref(null),
        ref(true),
        { align: 'start' }
      );

      expect(fixedPosition.value.style.right).toBe('16px');
    });
  });

  describe('RTL', () => {
    beforeEach(() => {
      document.body.innerHTML = '<div id="app" dir="rtl"></div>';
    });

    it('flips anchor direction in RTL (align=end anchors left)', () => {
      // align=end + RTL → anchorLeft=true → uses style.left
      setTrigger({ top: 100, bottom: 140, left: 100, right: 200 });
      setDropdown({ height: 100, width: 200 });

      const { fixedPosition } = useDropdownPosition(
        ref(null),
        ref(null),
        ref(true)
      );

      expect(fixedPosition.value.style.left).toBe('100px');
    });
  });
});
