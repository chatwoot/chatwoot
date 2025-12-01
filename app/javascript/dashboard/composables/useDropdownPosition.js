import { computed } from 'vue';
import { useElementBounding, useWindowSize } from '@vueuse/core';

/**
 * Auto-position dropdown based on available space
 * @param {Ref} triggerRef - Trigger element ref
 * @param {Ref} dropdownRef - Dropdown element ref
 * @returns {Object} { positionClasses, updatePosition }
 */
export function useDropdownPosition(triggerRef, dropdownRef) {
  const SAFE_MARGIN = 16;

  const triggerBounds = useElementBounding(triggerRef);
  const dropdownBounds = useElementBounding(dropdownRef);
  const { height: windowHeight, width: windowWidth } = useWindowSize();

  const positionClasses = computed(() => {
    if (!triggerRef.value || !dropdownRef.value)
      return 'top-full mt-2 ltr:left-0 rtl:right-0';

    const spaceBelow = windowHeight.value - triggerBounds.bottom.value;
    const spaceRight = windowWidth.value - triggerBounds.left.value;
    const dropdownHeight = dropdownBounds.height.value || 200;
    const dropdownWidth = dropdownBounds.width.value || 200;

    const vertical =
      spaceBelow >= dropdownHeight + SAFE_MARGIN
        ? 'top-full mt-2'
        : 'bottom-full mb-2';

    const horizontal =
      spaceRight >= dropdownWidth + SAFE_MARGIN
        ? 'ltr:left-0 rtl:right-0'
        : 'ltr:right-0 rtl:left-0';

    return `${vertical} ${horizontal}`;
  });

  const updatePosition = () => {
    triggerBounds.update();
    dropdownBounds.update();
  };

  return { positionClasses, updatePosition };
}
