import { mount } from '@vue/test-utils';
import { h, nextTick } from 'vue';
import DraggableReorderList from '../DraggableReorderList.vue';

// The component is pointer-driven, so we drive it through real pointer events on
// window while mocking the layout APIs jsdom does not implement: elementFromPoint
// (which card is under the cursor) and getBoundingClientRect (its geometry).
const elementAtPoint = { current: null };

const move = (clientX, clientY) =>
  window.dispatchEvent(new MouseEvent('pointermove', { clientX, clientY }));
const release = () => window.dispatchEvent(new MouseEvent('pointerup'));

// Stack the rows 50px apart, each 40px tall, inside a 500px-wide list.
const stubGeometry = wrapper => {
  wrapper.element.getBoundingClientRect = () => ({
    left: 0,
    right: 500,
    top: 0,
    bottom: 600,
  });
  wrapper.findAll('[data-drag-id]').forEach((li, index) => {
    const top = index * 50;
    li.element.getBoundingClientRect = () => ({
      top,
      height: 40,
      bottom: top + 40,
    });
  });
};

const mountList = (props = {}) =>
  mount(DraggableReorderList, {
    props: { items: [], ...props },
    slots: {
      item: scope => h('div', { class: 'card' }, scope.item.title),
      ghost: scope => h('div', { class: 'ghost' }, scope.item.title),
    },
    global: { stubs: { Icon: true, teleport: true } },
  });

describe('DraggableReorderList', () => {
  let wrapper;

  beforeEach(() => {
    elementAtPoint.current = null;
    document.elementFromPoint = vi.fn(() => elementAtPoint.current);
  });

  afterEach(() => {
    wrapper?.unmount();
    vi.useRealTimers();
  });

  const startDragging = async id => {
    stubGeometry(wrapper);
    wrapper.find(`[data-drag-id="${id}"]`).element.dispatchEvent(
      new MouseEvent('pointerdown', {
        button: 0,
        clientX: 250,
        clientY: 20,
        bubbles: true,
      })
    );
    await nextTick();
  };

  it('renders each item through the item slot', () => {
    wrapper = mountList({
      items: [
        { id: 1, title: 'Alpha' },
        { id: 2, title: 'Beta' },
      ],
    });

    const cards = wrapper.findAll('.card');
    expect(cards).toHaveLength(2);
    expect(cards[0].text()).toBe('Alpha');
    expect(wrapper.find('[data-drag-id="1"]').exists()).toBe(true);
    expect(wrapper.find('[data-drag-id="2"]').exists()).toBe(true);
  });

  it('shows a grab affordance only when enabled', () => {
    wrapper = mountList({ items: [{ id: 1, title: 'Alpha' }] });
    expect(wrapper.find('[data-drag-id="1"]').classes()).toContain(
      'cursor-grab'
    );

    wrapper.unmount();
    wrapper = mountList({ items: [{ id: 1, title: 'Alpha' }], disabled: true });
    expect(wrapper.find('[data-drag-id="1"]').classes()).not.toContain(
      'cursor-grab'
    );
  });

  it('does not start a drag when disabled', async () => {
    wrapper = mountList({
      items: [
        { id: 1, title: 'Alpha' },
        { id: 2, title: 'Beta' },
      ],
      disabled: true,
    });
    await startDragging(1);
    move(250, 200);
    await nextTick();

    expect(wrapper.emitted('dragging')).toBeUndefined();
  });

  it('emits dragging true then false across a drag', async () => {
    wrapper = mountList({
      items: [
        { id: 1, title: 'Alpha' },
        { id: 2, title: 'Beta' },
      ],
    });
    await startDragging(1);
    elementAtPoint.current = wrapper.find('[data-drag-id="2"]').element;
    move(250, 60);
    await nextTick();

    expect(wrapper.emitted('dragging')[0]).toEqual([true]);

    release();
    await nextTick();
    expect(wrapper.emitted('dragging')[1]).toEqual([false]);
  });

  it('emits the midpoint position when dropped between two rows', async () => {
    wrapper = mountList({
      items: [
        { id: 1, title: 'Alpha', position: 10 },
        { id: 2, title: 'Beta', position: 20 },
        { id: 3, title: 'Gamma', position: 30 },
      ],
    });
    await startDragging(1);

    // Hover the lower half of Beta (top 50, height 40 → midpoint 70) so the gap
    // sits before Gamma; dropping there lands halfway between Beta and Gamma.
    elementAtPoint.current = wrapper.find('[data-drag-id="2"]').element;
    move(250, 85);
    await nextTick();
    release();
    await nextTick();

    expect(wrapper.emitted('reorder')[0][0]).toEqual({ 1: 25 });
  });

  it('does not reorder when the only row on a page is dropped in place', async () => {
    // P1: dragging the lone article on a later page and releasing without
    // crossing to another page must be a no-op, not move it to the top.
    wrapper = mountList({
      items: [{ id: 5, title: 'Solo', position: 260 }],
      currentPage: 2,
      totalPages: 2,
    });
    await startDragging(5);
    move(250, 300);
    await nextTick();
    release();
    await nextTick();

    expect(wrapper.emitted('dragging')).toEqual([[true], [false]]);
    expect(wrapper.emitted('reorder')).toBeUndefined();
  });

  it('turns the page after dwelling on a pageable edge', async () => {
    vi.useFakeTimers();
    wrapper = mountList({
      items: [
        { id: 1, title: 'Alpha', position: 10 },
        { id: 2, title: 'Beta', position: 20 },
      ],
      currentPage: 1,
      totalPages: 2,
    });
    await startDragging(1);

    // Drag to the right edge over blank space (no card) and hold.
    elementAtPoint.current = null;
    move(490, 20);
    await nextTick();
    vi.advanceTimersByTime(600);

    expect(wrapper.emitted('navigatePage')[0]).toEqual([2]);
  });

  it('can still turn pages after releasing during a pending flip', async () => {
    // Releasing while a flip fetch is in flight must clear paging state, or every
    // later drag would be stuck unable to navigate.
    vi.useFakeTimers();
    wrapper = mountList({
      items: [
        { id: 1, title: 'Alpha', position: 10 },
        { id: 2, title: 'Beta', position: 20 },
      ],
      currentPage: 1,
      totalPages: 2,
    });

    // First drag: park at the edge to start a flip, then release before the new
    // page arrives (items never change here).
    await startDragging(1);
    elementAtPoint.current = null;
    move(490, 20);
    await nextTick();
    vi.advanceTimersByTime(600);
    release();
    await nextTick();

    // Second drag must be able to flip again.
    await startDragging(1);
    elementAtPoint.current = null;
    move(490, 20);
    await nextTick();
    vi.advanceTimersByTime(600);

    expect(wrapper.emitted('navigatePage')).toEqual([[2], [2]]);
  });
});
