import { computed, unref, watch } from 'vue';
import { useElementBounding, useWindowSize } from '@vueuse/core';

const FALLBACK_SIZE = 200;
const SAFE_MARGIN = 16;
const GAP = 8;

/**
 * Auto-position a floating element based on available viewport space.
 *
 * @param {Ref} triggerRef - Trigger element ref
 * @param {Ref} dropdownRef - Dropdown/popover element ref
 * @param {Ref} enabled - Whether to calculate position
 * @param {Object} options
 * @param {Ref}    [options.container] - Constraining container ref
 * @param {number} [options.margin=16] - Min distance from viewport/container edges
 * @param {string} [options.align='end'] - 'start' or 'end' (flips automatically for RTL)
 */
export function useDropdownPosition(
  triggerRef,
  dropdownRef,
  enabled,
  { container = null, margin = SAFE_MARGIN, align = 'end' } = {}
) {
  const trigger = useElementBounding(triggerRef);
  const dropdown = useElementBounding(dropdownRef);
  const bounds = useElementBounding(container);
  const { width: winWidth, height: winHeight } = useWindowSize();

  const isRTL = computed(
    () => document.querySelector('#app[dir]')?.getAttribute('dir') === 'rtl'
  );

  // Whether to anchor to the left edge of the trigger
  const anchorLeft = computed(() => (align === 'start') !== isRTL.value);

  const verticalClass = computed(() => {
    if (!unref(enabled)) return 'top-full mt-2';
    const dh = dropdown.height.value || FALLBACK_SIZE;
    const spaceBelow = winHeight.value - trigger.bottom.value;
    const spaceAbove = trigger.top.value;
    // Only flip above if it fits there; otherwise stay below (more room or equal)
    if (spaceBelow >= dh + margin) return 'top-full mt-2';
    if (spaceAbove >= dh + margin) return 'bottom-full mb-2';
    return spaceBelow >= spaceAbove ? 'top-full mt-2' : 'bottom-full mb-2';
  });

  // Relative mode: Tailwind class + style for absolute-in-parent dropdowns
  const position = computed(() => {
    if (!unref(enabled)) return { class: 'top-full mt-2', style: {} };

    const dw = dropdown.width.value || FALLBACK_SIZE;
    const leftBound = container ? bounds.left.value : 0;
    const rightBound = container ? bounds.right.value : winWidth.value;
    const style = {};

    if (anchorLeft.value) {
      const available = rightBound - trigger.left.value;
      const overflow = dw - available;
      style.left = overflow > 0 ? `-${overflow}px` : '0px';
    } else {
      const available = trigger.right.value - leftBound;
      const overflow = dw - available;
      style.right = overflow > 0 ? `-${overflow}px` : '0px';
    }

    return { class: verticalClass.value, style };
  });

  // Fixed mode: styles for teleported popovers
  const fixedPosition = computed(() => {
    if (!unref(enabled)) return { class: 'fixed z-[9999]', style: {} };

    const dh = dropdown.height.value || FALLBACK_SIZE;
    const dw = dropdown.width.value || FALLBACK_SIZE;
    const spaceBelow = winHeight.value - trigger.bottom.value;
    const style = {};

    // Vertical: prefer below, flip above only if it fits, else pick the larger side
    const spaceAbove = trigger.top.value;
    const placeAbove =
      spaceBelow < dh + margin &&
      (spaceAbove >= dh + margin || spaceAbove > spaceBelow);

    if (placeAbove) {
      style.bottom = `${winHeight.value - trigger.top.value + GAP}px`;
      style.maxHeight = `${spaceAbove - GAP - margin}px`;
    } else {
      style.top = `${trigger.bottom.value + GAP}px`;
      style.maxHeight = `${spaceBelow - GAP - margin}px`;
    }

    // Horizontal
    if (anchorLeft.value) {
      const left = trigger.left.value;
      if (left + dw > winWidth.value - margin) {
        style.right = `${margin}px`;
      } else {
        style.left = `${Math.max(margin, left)}px`;
      }
    } else {
      const right = winWidth.value - trigger.right.value;
      if (trigger.right.value - dw < margin) {
        style.left = `${margin}px`;
      } else {
        style.right = `${right}px`;
      }
    }

    return { class: 'fixed z-[9999]', style };
  });

  const updatePosition = () => {
    trigger.update();
    dropdown.update();
    if (container) bounds.update();
  };

  // Update position when dropdown opens to ensure RTL state is current
  watch(
    () => unref(enabled),
    isEnabled => {
      if (isEnabled) updatePosition();
    }
  );

  return { position, fixedPosition, updatePosition };
}
