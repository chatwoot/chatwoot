import mentionSelectionKeyboardMixin from '../mentionSelectionKeyboardMixin';
import { shallowMount } from '@vue/test-utils';

const buildComponent = ({ data = {}, methods = {} }) => ({
  render() {},
  data() {
    return data;
  },
  methods,
  mixins: [mentionSelectionKeyboardMixin],
});

describe('mentionSelectionKeyboardMixin', () => {
  test('register listeners', () => {
    jest.spyOn(document, 'addEventListener');
    const Component = buildComponent({});
    shallowMount(Component);
    // undefined expected as the method is not defined in the component
    expect(document.addEventListener).toHaveBeenCalledWith(
      'keydown',
      undefined
    );
  });

  test('processKeyDownEvent updates index on arrow up', () => {
    const Component = buildComponent({
      data: { selectedIndex: 0, items: [1, 2, 3] },
    });
    const wrapper = shallowMount(Component);
    wrapper.vm.processKeyDownEvent({
      ctrlKey: true,
      key: 'p',
      preventDefault: jest.fn(),
    });
    expect(wrapper.vm.selectedIndex).toBe(2);
  });

  test('processKeyDownEvent updates index on arrow down', () => {
    const Component = buildComponent({
      data: { selectedIndex: 0, items: [1, 2, 3] },
    });
    const wrapper = shallowMount(Component);
    wrapper.vm.processKeyDownEvent({
      key: 'ArrowDown',
      preventDefault: jest.fn(),
    });
    expect(wrapper.vm.selectedIndex).toBe(1);
  });

  test('processKeyDownEvent calls select methods on Enter Key', () => {
    const onSelectMockFn = jest.fn();
    const Component = buildComponent({
      data: { selectedIndex: 0, items: [1, 2, 3] },
      methods: { onSelect: () => onSelectMockFn('enterKey pressed') },
    });
    const wrapper = shallowMount(Component);
    wrapper.vm.processKeyDownEvent({
      key: 'Enter',
      preventDefault: jest.fn(),
    });
    expect(onSelectMockFn).toHaveBeenCalledWith('enterKey pressed');
    wrapper.vm.onSelect();
  });
});
