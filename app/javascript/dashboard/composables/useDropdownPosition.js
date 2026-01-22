import { computed, unref, watch } from 'vue';
import { useElementBounding, useWindowSize } from '@vueuse/core';

const FALLBACK_SIZE = 200;
const RTL_DIRECTION = 'rtl';

/**
 * Auto-position dropdown based on available space within container
 * Returns reactive position object containing class and style
 *
 * @param {Ref} triggerRef - Trigger element ref
 * @param {Ref} dropdownRef - Dropdown element ref
 * @param {Ref} enabled - Whether to calculate position
 * @param {Object} options - { container: Ref, margin: Number }
 */
export function useDropdownPosition(
  triggerRef,
  dropdownRef,
  enabled,
  { container = null, margin = 16 } = {}
) {
  const trigger = useElementBounding(triggerRef);
  const dropdown = useElementBounding(dropdownRef);
  const bounds = useElementBounding(container);
  const { width: winWidth, height: winHeight } = useWindowSize();

  const isRTL = computed(
    () =>
      document.querySelector('#app[dir]')?.getAttribute('dir') === RTL_DIRECTION
  );

  const position = computed(() => {
    // Default fallback if not enabled or refs aren't ready
    if (!unref(enabled)) {
      return { class: 'top-full mt-2', style: {} };
    }

    const dropdownHeight = dropdown.height.value || FALLBACK_SIZE;
    const dropdownWidth = dropdown.width.value || FALLBACK_SIZE;

    /* ---------- Vertical (Tailwind Classes) ---------- */
    const spaceBelow = winHeight.value - trigger.bottom.value;
    const className =
      spaceBelow >= dropdownHeight + margin
        ? 'top-full mt-2'
        : 'bottom-full mb-2';

    /* ---------- Horizontal (Inline Styles for precise alignment) ---------- */
    const leftBound = container ? bounds.left.value : 0;
    const rightBound = container ? bounds.right.value : winWidth.value;

    const style = {};

    if (isRTL.value) {
      const availableLeft = trigger.right.value - leftBound;
      const overflow = dropdownWidth - availableLeft;
      style.right = overflow > 0 ? `-${overflow}px` : '0px';
    } else {
      const availableRight = rightBound - trigger.left.value;
      const overflow = dropdownWidth - availableRight;
      style.left = overflow > 0 ? `-${overflow}px` : '0px';
    }

    return { class: className, style };
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

  return { position, updatePosition };
}
