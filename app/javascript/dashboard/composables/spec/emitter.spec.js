import { shallowMount } from '@vue/test-utils';
import { emitter } from 'shared/helpers/mitt';
import { useEmitter } from '../emitter';

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    on: vi.fn(),
    off: vi.fn(),
  },
}));

describe('useEmitter', () => {
  let wrapper;
  const eventName = 'my-event';
  const callback = vi.fn();

  beforeEach(() => {
    wrapper = shallowMount({
      template: `
        <div>
          Hello world
        </div>
      `,
      setup() {
        return {
          cleanup: useEmitter(eventName, callback),
        };
      },
    });
  });

  it('should add an event listener on mount', () => {
    expect(emitter.on).toHaveBeenCalledWith(eventName, callback);
  });

  it('should remove the event listener when the component is unmounted', () => {
    wrapper.destroy();
    expect(emitter.off).toHaveBeenCalledWith(eventName, callback);
  });

  it('should return the cleanup function', () => {
    const cleanup = wrapper.vm.cleanup;
    expect(typeof cleanup).toBe('function');
    cleanup();
    expect(emitter.off).toHaveBeenCalledWith(eventName, callback);
  });
});
