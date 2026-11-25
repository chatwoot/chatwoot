import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest';

const WIDTH_KEY = 'internal_chat_sidebar_width';
const COLLAPSED_KEY = 'internal_chat_sidebar_collapsed';

// This project's jsdom environment ships without localStorage, so the suite
// provides its own in-memory one.
const createLocalStorageStub = () => {
  const store = new Map();
  return {
    getItem: key => (store.has(key) ? store.get(key) : null),
    setItem: (key, value) => store.set(key, String(value)),
    removeItem: key => store.delete(key),
    clear: () => store.clear(),
  };
};

// The composable keeps its state at module scope so the layout and the sidebar
// share it, which means each example needs a fresh module instance.
const loadComposable = async () => {
  vi.resetModules();
  return import('../useInternalChatSidebar');
};

describe('useInternalChatSidebar', () => {
  beforeEach(() => {
    vi.stubGlobal('localStorage', createLocalStorageStub());
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('starts expanded at the default width when nothing is stored', async () => {
    const { useInternalChatSidebar, DEFAULT_WIDTH } = await loadComposable();
    const { sidebarWidth, isCollapsed } = useInternalChatSidebar();

    expect(sidebarWidth.value).toBe(DEFAULT_WIDTH);
    expect(isCollapsed.value).toBe(false);
  });

  it('restores the stored width and collapsed state', async () => {
    window.localStorage.setItem(WIDTH_KEY, '320');
    window.localStorage.setItem(COLLAPSED_KEY, 'true');

    const { useInternalChatSidebar } = await loadComposable();
    const { sidebarWidth, isCollapsed } = useInternalChatSidebar();

    expect(sidebarWidth.value).toBe(320);
    expect(isCollapsed.value).toBe(true);
  });

  it('clamps a stored width that falls outside the allowed range', async () => {
    window.localStorage.setItem(WIDTH_KEY, '9999');

    const { useInternalChatSidebar, MAX_WIDTH } = await loadComposable();

    expect(useInternalChatSidebar().sidebarWidth.value).toBe(MAX_WIDTH);
  });

  it('clamps drag updates between the drag floor and the max width', async () => {
    const { useInternalChatSidebar, MAX_WIDTH, DRAG_FLOOR } =
      await loadComposable();
    const { sidebarWidth, setSidebarWidth } = useInternalChatSidebar();

    setSidebarWidth(10);
    expect(sidebarWidth.value).toBe(DRAG_FLOOR);

    setSidebarWidth(10000);
    expect(sidebarWidth.value).toBe(MAX_WIDTH);
  });

  it('collapses when the drag is released below the collapse threshold', async () => {
    const { useInternalChatSidebar, COLLAPSE_AT, DEFAULT_WIDTH } =
      await loadComposable();
    const { sidebarWidth, isCollapsed, setSidebarWidth, commitWidth } =
      useInternalChatSidebar();

    setSidebarWidth(COLLAPSE_AT - 1);
    commitWidth();

    expect(isCollapsed.value).toBe(true);
    expect(window.localStorage.getItem(COLLAPSED_KEY)).toBe('true');
    // The width is kept for the next expand instead of being persisted tiny.
    expect(sidebarWidth.value).toBe(DEFAULT_WIDTH);
  });

  it('snaps to the minimum width when released between the threshold and the minimum', async () => {
    const { useInternalChatSidebar, COLLAPSE_AT, MIN_WIDTH } =
      await loadComposable();
    const { sidebarWidth, isCollapsed, setSidebarWidth, commitWidth } =
      useInternalChatSidebar();

    setSidebarWidth(COLLAPSE_AT + 1);
    commitWidth();

    expect(isCollapsed.value).toBe(false);
    expect(sidebarWidth.value).toBe(MIN_WIDTH);
    expect(window.localStorage.getItem(WIDTH_KEY)).toBe(String(MIN_WIDTH));
  });

  it('persists a width committed inside the allowed range', async () => {
    const { useInternalChatSidebar } = await loadComposable();
    const { sidebarWidth, setSidebarWidth, commitWidth } =
      useInternalChatSidebar();

    setSidebarWidth(300);
    commitWidth();

    expect(sidebarWidth.value).toBe(300);
    expect(window.localStorage.getItem(WIDTH_KEY)).toBe('300');
  });

  it('restores the last committed width when expanding again', async () => {
    const { useInternalChatSidebar } = await loadComposable();
    const { sidebarWidth, isCollapsed, setSidebarWidth, commitWidth, expand } =
      useInternalChatSidebar();

    setSidebarWidth(360);
    commitWidth();
    setSidebarWidth(100);
    commitWidth();
    expect(isCollapsed.value).toBe(true);

    expand();

    expect(isCollapsed.value).toBe(false);
    expect(sidebarWidth.value).toBe(360);
    expect(window.localStorage.getItem(COLLAPSED_KEY)).toBe('false');
  });

  it('shares state between callers', async () => {
    const { useInternalChatSidebar } = await loadComposable();
    const layout = useInternalChatSidebar();
    const sidebar = useInternalChatSidebar();

    sidebar.collapse();

    expect(layout.isCollapsed.value).toBe(true);
  });
});
