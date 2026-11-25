import { ref } from 'vue';

const WIDTH_STORAGE_KEY = 'internal_chat_sidebar_width';
const COLLAPSED_STORAGE_KEY = 'internal_chat_sidebar_collapsed';

export const DEFAULT_WIDTH = 256;
export const MIN_WIDTH = 200;
export const MAX_WIDTH = 420;
// Releasing the drag below this collapses the sidebar. Between this and
// MIN_WIDTH it snaps back to MIN_WIDTH instead.
export const COLLAPSE_AT = 140;
// Visual floor while dragging, so the sidebar can shrink past MIN_WIDTH and
// show that letting go there collapses it.
export const DRAG_FLOOR = 96;

const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

const readStoredWidth = () => {
  const stored = Number(window.localStorage.getItem(WIDTH_STORAGE_KEY));
  if (!stored) return DEFAULT_WIDTH;
  return clamp(stored, MIN_WIDTH, MAX_WIDTH);
};

// Module scope so the layout (expand rail) and the sidebar itself share one
// state without threading it through props, same idea as the shared popover
// state in components-next/sidebar/provider.js.
const sidebarWidth = ref(readStoredWidth());
const isCollapsed = ref(
  window.localStorage.getItem(COLLAPSED_STORAGE_KEY) === 'true'
);
// Width to restore when the sidebar is expanded again.
let expandedWidth = sidebarWidth.value;

export function useInternalChatSidebar() {
  const setSidebarWidth = width => {
    sidebarWidth.value = clamp(width, DRAG_FLOOR, MAX_WIDTH);
  };

  const expand = () => {
    isCollapsed.value = false;
    sidebarWidth.value = expandedWidth;
    window.localStorage.setItem(COLLAPSED_STORAGE_KEY, 'false');
  };

  const collapse = () => {
    isCollapsed.value = true;
    sidebarWidth.value = expandedWidth;
    window.localStorage.setItem(COLLAPSED_STORAGE_KEY, 'true');
  };

  const toggleCollapsed = () => {
    if (isCollapsed.value) expand();
    else collapse();
  };

  // Called when a drag ends: either collapse, or settle on a usable width.
  const commitWidth = () => {
    if (sidebarWidth.value < COLLAPSE_AT) {
      collapse();
      return;
    }
    expandedWidth = clamp(sidebarWidth.value, MIN_WIDTH, MAX_WIDTH);
    sidebarWidth.value = expandedWidth;
    window.localStorage.setItem(WIDTH_STORAGE_KEY, String(expandedWidth));
  };

  return {
    sidebarWidth,
    isCollapsed,
    setSidebarWidth,
    commitWidth,
    expand,
    collapse,
    toggleCollapsed,
  };
}
