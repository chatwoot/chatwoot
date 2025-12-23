import { computed } from 'vue';
import { useElementBounding, useWindowSize } from '@vueuse/core';

/**
 * Auto-position dropdown based on available space
 * @param {Ref} triggerRef - Trigger element ref
 * @param {Ref} dropdownRef - Dropdown element ref
 * @param {Ref} enabled - Whether to calculate position
 * @returns {Object} { positionClasses, updatePosition }
 */
export function useDropdownPosition(triggerRef, dropdownRef, enabled) {
  const SAFE_MARGIN = 16;
  const RTL = 'rtl';

  const triggerBounds = useElementBounding(triggerRef);
  const dropdownBounds = useElementBounding(dropdownRef);
  const { height: windowHeight, width: windowWidth } = useWindowSize();

  const positionClasses = computed(() => {
    // Don't calculate if not enabled
    if (!enabled?.value) {
      return 'top-full mt-2 ltr:left-0 rtl:right-0';
    }

    if (!triggerRef.value || !dropdownRef.value) {
      return 'top-full mt-2 ltr:left-0 rtl:right-0';
    }

    const spaceBelow = windowHeight.value - triggerBounds.bottom.value;
    const dropdownHeight = dropdownBounds.height.value || 200;
    const dropdownWidth = dropdownBounds.width.value || 200;

    // Check if RTL by checking app div with dir attribute
    const appDiv = document.querySelector('#app[dir]');
    const isRTL = appDiv?.getAttribute('dir') === RTL;

    // Use appropriate edge based on text direction
    const triggerEdge = isRTL
      ? triggerBounds.right.value
      : triggerBounds.left.value;
    const wouldOverflow = isRTL
      ? triggerEdge - dropdownWidth - SAFE_MARGIN < 0
      : triggerEdge + dropdownWidth + SAFE_MARGIN > windowWidth.value;

    const vertical =
      spaceBelow >= dropdownHeight + SAFE_MARGIN
        ? 'top-full mt-2'
        : 'bottom-full mb-2';

    const horizontal = wouldOverflow
      ? 'ltr:right-0 rtl:left-0'
      : 'ltr:left-0 rtl:right-0';

    return `${vertical} ${horizontal}`;
  });

  const updatePosition = () => {
    triggerBounds.update();
    dropdownBounds.update();
  };

  return { positionClasses, updatePosition };
}
