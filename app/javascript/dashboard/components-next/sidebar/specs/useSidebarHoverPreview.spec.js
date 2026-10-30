import { ref } from 'vue';
import { mount } from '@vue/test-utils';
import { useSidebarHoverPreview } from '../useSidebarHoverPreview';

const mountPreview = () => {
  const sidebar = document.createElement('aside');
  const insideSidebar = document.createElement('button');
  sidebar.appendChild(insideSidebar);
  document.body.appendChild(sidebar);

  const menu = document.createElement('div');
  menu.setAttribute('data-popover-content', '');
  const insideMenu = document.createElement('button');
  menu.appendChild(insideMenu);
  document.body.appendChild(menu);

  let preview;
  const wrapper = mount({
    setup() {
      preview = useSidebarHoverPreview(ref(sidebar));
      return () => null;
    },
  });

  return { wrapper, preview, insideSidebar, insideMenu };
};

const pointerOver = target =>
  target.dispatchEvent(new Event('pointerover', { bubbles: true }));

describe('useSidebarHoverPreview', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
    document.body.innerHTML = '';
  });

  it('opens on a mouse pointer and ignores touch', () => {
    const { preview } = mountPreview();

    preview.open({ pointerType: 'touch' });
    expect(preview.isHovered.value).toBe(false);

    preview.open({ pointerType: 'mouse' });
    expect(preview.isHovered.value).toBe(true);
  });

  it('closes once the pointer rests outside the sidebar', () => {
    const { preview } = mountPreview();
    preview.open();

    pointerOver(document.body);
    expect(preview.isHovered.value).toBe(true);

    vi.runAllTimers();
    expect(preview.isHovered.value).toBe(false);
  });

  it('stays open while the pointer is over the sidebar or a menu opened from it', () => {
    const { preview, insideSidebar, insideMenu } = mountPreview();
    preview.open();

    pointerOver(insideSidebar);
    vi.runAllTimers();
    expect(preview.isHovered.value).toBe(true);

    pointerOver(insideMenu);
    vi.runAllTimers();
    expect(preview.isHovered.value).toBe(true);
  });

  it('cancels a pending close when the pointer comes back', () => {
    const { preview, insideSidebar } = mountPreview();
    preview.open();

    pointerOver(document.body);
    pointerOver(insideSidebar);
    vi.runAllTimers();

    expect(preview.isHovered.value).toBe(true);
  });

  it('closes on Escape', () => {
    const { preview } = mountPreview();
    preview.open();

    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));

    expect(preview.isHovered.value).toBe(false);
  });

  it('closes immediately when asked to', () => {
    const { preview } = mountPreview();
    preview.open();

    preview.close();

    expect(preview.isHovered.value).toBe(false);
  });
});
