import { shallowMount, createLocalVue } from '@vue/test-utils';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';

const localVue = createLocalVue();

const buildComponent = ({ data = {}, methods = {} }) => ({
  render() {},
  data() {
    return { ...data, selectedIndex: 0, items: [1, 2, 3] };
  },
  methods: { ...methods, onSelect: vi.fn(), adjustScroll: vi.fn() },
  mixins: [keyboardEventListenerMixins],
});

describe('mentionSelectionKeyboardMixin', () => {
  let wrapper;

  beforeEach(() => {
    const Component = buildComponent({});
    wrapper = shallowMount(Component, { localVue });
  });

  it('ArrowUp and Control+KeyP update selectedIndex correctly', () => {
    const preventDefault = vi.fn();
    const keyboardEvents = wrapper.vm.getKeyboardEvents();

    if (keyboardEvents && keyboardEvents.ArrowUp) {
      keyboardEvents.ArrowUp.action({ preventDefault });
      expect(wrapper.vm.selectedIndex).toBe(2);
      expect(preventDefault).toHaveBeenCalled();
    }

    wrapper.setData({ selectedIndex: 1 });
    if (keyboardEvents && keyboardEvents['Control+KeyP']) {
      keyboardEvents['Control+KeyP'].action({ preventDefault });
      expect(wrapper.vm.selectedIndex).toBe(0);
      expect(preventDefault).toHaveBeenCalledTimes(2);
    }
  });

  it('ArrowDown and Control+KeyN update selectedIndex correctly', () => {
    const preventDefault = vi.fn();
    const keyboardEvents = wrapper.vm.getKeyboardEvents();

    if (keyboardEvents && keyboardEvents.ArrowDown) {
      keyboardEvents.ArrowDown.action({ preventDefault });
      expect(wrapper.vm.selectedIndex).toBe(1);
      expect(preventDefault).toHaveBeenCalled();
    }

    wrapper.setData({ selectedIndex: 1 });
    if (keyboardEvents && keyboardEvents['Control+KeyN']) {
      keyboardEvents['Control+KeyN'].action({ preventDefault });
      expect(wrapper.vm.selectedIndex).toBe(2);
      expect(preventDefault).toHaveBeenCalledTimes(2);
    }
  });

  it('Enter key triggers onSelect method', () => {
    const preventDefault = vi.fn();
    const keyboardEvents = wrapper.vm.getKeyboardEvents();

    if (keyboardEvents && keyboardEvents.Enter) {
      keyboardEvents.Enter.action({ preventDefault });
      expect(wrapper.vm.onSelect).toHaveBeenCalled();
      expect(preventDefault).toHaveBeenCalled();
    }
  });
});
