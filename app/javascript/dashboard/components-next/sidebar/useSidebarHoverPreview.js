import { ref, onBeforeUnmount } from 'vue';
import { useEventListener } from '@vueuse/core';

// Menus opened from the sidebar are teleported out of it, so the pointer leaves
// the sidebar on its way to them. Keep the preview open across that gap and for
// as long as the pointer stays inside one of those layers.
const PREVIEW_LAYER_SELECTOR = '[data-popover-content], [data-dropdown-menu]';
const CLOSE_DELAY = 180;

/**
 * Reveals the full sidebar while the pointer rests on the collapsed rail. The
 * preview is transient: it never writes to the stored sidebar width.
 *
 * @param {import('vue').Ref<HTMLElement>} sidebarRef Sidebar root element.
 */
export function useSidebarHoverPreview(sidebarRef) {
  const isHovered = ref(false);
  let closeTimer = null;

  const cancelClose = () => clearTimeout(closeTimer);

  const close = () => {
    cancelClose();
    isHovered.value = false;
  };

  const open = event => {
    // Touch devices use the drawer, and a tap would leave the preview stuck open.
    if (event?.pointerType === 'touch') return;
    cancelClose();
    isHovered.value = true;
  };

  const closeWhenPointerLeaves = event => {
    if (!isHovered.value) return;

    cancelClose();
    const staysWithinPreview =
      sidebarRef.value?.contains(event.target) ||
      event.target?.closest?.(PREVIEW_LAYER_SELECTOR);
    if (staysWithinPreview) return;

    closeTimer = setTimeout(close, CLOSE_DELAY);
  };

  const closeOnEscape = event => {
    if (event.key === 'Escape') close();
  };

  useEventListener(document, 'pointerover', closeWhenPointerLeaves);
  useEventListener(document, 'keydown', closeOnEscape);
  useEventListener(document, 'pointerleave', close);
  useEventListener(window, 'blur', close);
  onBeforeUnmount(cancelClose);

  return { isHovered, open, close };
}
