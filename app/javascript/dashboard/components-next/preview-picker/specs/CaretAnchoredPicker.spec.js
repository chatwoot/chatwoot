import { ref } from 'vue';
import { mount } from '@vue/test-utils';
import CaretAnchoredPicker from '../CaretAnchoredPicker.vue';

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => ref(false),
}));

vi.mock('dashboard/composables/useKeyboardEvents', () => ({
  useKeyboardEvents: vi.fn(),
}));

const ITEM = { id: 1, label: 'Item', title: 'Item' };

const mountPicker = (props = {}) =>
  mount(CaretAnchoredPicker, {
    props: { items: [ITEM], search: '', ...props },
    global: {
      stubs: { TeleportWithDirection: { template: '<div><slot /></div>' } },
    },
  });

// The owner filters its items by the search and passes them back, so a search and the items
// that answer it arrive together.
const answer = (wrapper, search, items) => wrapper.setProps({ search, items });

describe('CaretAnchoredPicker', () => {
  it('hands back what was typed once the search matches nothing', async () => {
    const wrapper = mountPicker();

    await answer(wrapper, 'It', [ITEM]);
    expect(wrapper.emitted('release')).toBeUndefined();

    await answer(wrapper, 'It /', []);
    expect(wrapper.emitted('release')).toEqual([[{ text: 'It /' }]]);
  });

  it('hands back only what was typed after the search it opened with', async () => {
    const wrapper = mountPicker({ search: 'sau' });

    await answer(wrapper, 'saux', []);

    expect(wrapper.emitted('release')).toEqual([[{ text: 'x' }]]);
  });

  it('asks to replace the document text when the search was edited into it', async () => {
    const wrapper = mountPicker({ search: 'sau' });

    await answer(wrapper, 'sx', []);

    expect(wrapper.emitted('release')).toEqual([
      [{ text: 'sx', replace: true }],
    ]);
  });

  it('waits for the items while they are loading', async () => {
    const wrapper = mountPicker({ isLoading: true });

    await answer(wrapper, 'x', []);
    expect(wrapper.emitted('release')).toBeUndefined();

    await wrapper.setProps({ isLoading: false });
    expect(wrapper.emitted('release')).toEqual([[{ text: 'x' }]]);
  });

  it('keeps a search it opened with, even when nothing matches it once loaded', async () => {
    const wrapper = mountPicker({ search: 'zz', items: [], isLoading: true });

    await wrapper.setProps({ isLoading: false });

    expect(wrapper.emitted('release')).toBeUndefined();
  });

  it('has nothing to hand back once the search is cleared', async () => {
    const wrapper = mountPicker({ search: 'sm' });

    await answer(wrapper, '', []);

    expect(wrapper.emitted('release')).toBeUndefined();
  });

  it('keeps the search when a filter empties the list without anything typed', async () => {
    const wrapper = mountPicker();

    await answer(wrapper, 'jo', [ITEM]);
    await wrapper.setProps({ items: [] });

    expect(wrapper.emitted('release')).toBeUndefined();
  });
});
