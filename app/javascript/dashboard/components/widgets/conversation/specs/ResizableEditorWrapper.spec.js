import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ResizableEditorWrapper from '../ResizableEditorWrapper.vue';

vi.mock('@vueuse/core', () => ({
  useEventListener: (target, event, handler, options) =>
    target.addEventListener(event, handler, options),
}));

const CONTAINER_HEIGHT = 800;
const DEFAULT_HEIGHT = 120;
const MIN_HEIGHT = 80;
const COLLAPSE_DISTANCE = 48;
const START_Y = 500;

const mountWrapper = () =>
  mount(ResizableEditorWrapper, {
    props: { containerHeight: CONTAINER_HEIGHT },
    slots: { default: '<div class="resizable-editor-body" />' },
    attachTo: document.body,
  });

const editorHeight = wrapper =>
  parseInt(wrapper.element.style.getPropertyValue('--editor-height'), 10);
const collapseProgress = wrapper =>
  Number(wrapper.element.style.getPropertyValue('--editor-collapse-progress'));
const isFading = wrapper =>
  wrapper
    .find('.resizable-editor-body')
    .element.parentElement.className.includes('--editor-collapse-progress');

// Positive distance drags the handle down, shrinking the editor.
const dragBy = async (wrapper, distance) => {
  document.dispatchEvent(
    new MouseEvent('mousemove', { clientY: START_Y + distance })
  );
  await nextTick();
};

const releaseDrag = async () => {
  document.dispatchEvent(new MouseEvent('mouseup'));
  await nextTick();
};

describe('ResizableEditorWrapper', () => {
  let wrapper;

  beforeEach(async () => {
    wrapper = mountWrapper();
    await wrapper
      .find('.cursor-row-resize')
      .trigger('mousedown', { clientY: START_Y });
  });

  afterEach(() => {
    wrapper.unmount();
  });

  it('stops shrinking at the minimum height', async () => {
    await dragBy(wrapper, DEFAULT_HEIGHT - MIN_HEIGHT + 10);

    expect(editorHeight(wrapper)).toBe(MIN_HEIGHT);
    expect(wrapper.emitted('collapse')).toBeUndefined();
  });

  it('fades the editor as the handle is pulled past the minimum', async () => {
    await dragBy(wrapper, DEFAULT_HEIGHT - MIN_HEIGHT + COLLAPSE_DISTANCE / 2);

    expect(collapseProgress(wrapper)).toBe(0.5);
    expect(isFading(wrapper)).toBe(true);
    expect(wrapper.emitted('collapse')).toBeUndefined();
  });

  it('springs back when released before the collapse distance', async () => {
    await dragBy(wrapper, DEFAULT_HEIGHT - MIN_HEIGHT + COLLAPSE_DISTANCE / 2);
    await releaseDrag();

    expect(collapseProgress(wrapper)).toBe(0);
    expect(isFading(wrapper)).toBe(false);
    expect(editorHeight(wrapper)).toBe(MIN_HEIGHT);
    expect(wrapper.emitted('collapse')).toBeUndefined();
    expect(document.body.style.cursor).toBe('');
  });

  it('collapses once the handle travels the full collapse distance', async () => {
    await dragBy(wrapper, DEFAULT_HEIGHT - MIN_HEIGHT + COLLAPSE_DISTANCE);

    expect(wrapper.emitted('collapse')).toHaveLength(1);
    expect(collapseProgress(wrapper)).toBe(0);
    expect(isFading(wrapper)).toBe(false);
    expect(editorHeight(wrapper)).toBe(DEFAULT_HEIGHT);
    expect(document.body.style.cursor).toBe('');
  });

  it('collapses from a touch drag as well', async () => {
    await releaseDrag();
    await wrapper
      .find('.cursor-row-resize')
      .trigger('touchstart', { touches: [{ clientY: START_Y }] });
    const touchMove = Object.assign(
      new Event('touchmove', { cancelable: true }),
      {
        touches: [
          {
            clientY: START_Y + DEFAULT_HEIGHT - MIN_HEIGHT + COLLAPSE_DISTANCE,
          },
        ],
      }
    );
    document.dispatchEvent(touchMove);
    await nextTick();

    expect(wrapper.emitted('collapse')).toHaveLength(1);
    expect(touchMove.defaultPrevented).toBe(true);
  });

  it('ignores further movement after collapsing', async () => {
    await dragBy(wrapper, DEFAULT_HEIGHT - MIN_HEIGHT + COLLAPSE_DISTANCE);
    await dragBy(wrapper, DEFAULT_HEIGHT - MIN_HEIGHT + COLLAPSE_DISTANCE * 2);

    expect(wrapper.emitted('collapse')).toHaveLength(1);
    expect(editorHeight(wrapper)).toBe(DEFAULT_HEIGHT);
  });
});
