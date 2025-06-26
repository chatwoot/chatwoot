import { shallowMount } from '@vue/test-utils';
import { emitter } from 'shared/helpers/mitt';
import { useEmitter } from '../emitter';
import { defineComponent } from 'vue';

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    on: vi.fn(),
    off: vi.fn(),
  },
}));

describe('useEmitter', () => {
  const eventName = 'my-event';
  const callback = vi.fn();

  let wrapper;

  const TestComponent = defineComponent({
    setup() {
      return {
        cleanup: useEmitter(eventName, callback),
      };
    },
    template: '<div>Hello world</div>',
  });

  beforeEach(() => {
    wrapper = shallowMount(TestComponent);
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('should add an event listener on mount', () => {
    expect(emitter.on).toHaveBeenCalledWith(eventName, callback);
  });

  it('should remove the event listener when the component is unmounted', async () => {
    await wrapper.unmount();
    expect(emitter.off).toHaveBeenCalledWith(eventName, callback);
  });

  it('should return the cleanup function', () => {
    const cleanup = wrapper.vm.cleanup;
    expect(typeof cleanup).toBe('function');
    cleanup();
    expect(emitter.off).toHaveBeenCalledWith(eventName, callback);
  });
});
