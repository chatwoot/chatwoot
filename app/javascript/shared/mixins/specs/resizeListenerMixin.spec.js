import { mount } from '@vue/test-utils';
import resizeListenerMixin from '../resizeListenerMixin';

jest.useFakeTimers();

describe('resizeListenerMixin', () => {
  let wrapper;
  const TestComponent = {
    render() {},
    mixins: [resizeListenerMixin],
    methods: {
      handleResize: jest.fn(),
    },
  };

  beforeEach(() => {
    wrapper = mount(TestComponent);
  });

  it('adds resize listener on mount', () => {
    const addEventListenerSpy = jest.spyOn(window, 'addEventListener');
    mount(TestComponent);
    expect(addEventListenerSpy).toHaveBeenCalledWith(
      'resize',
      expect.any(Function)
    );
  });

  it('removes resize listener before destruction', () => {
    const removeEventListenerSpy = jest.spyOn(window, 'removeEventListener');
    wrapper.destroy();
    expect(removeEventListenerSpy).toHaveBeenCalledWith(
      'resize',
      expect.any(Function)
    );
  });
});
