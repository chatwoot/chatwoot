import { shallowMount } from '@vue/test-utils';
import { emitter } from 'shared/helpers/mitt';
import { useEmitter } from '../emitter';

jest.mock('shared/helpers/mitt', () => ({
  emitter: {
    on: jest.fn(),
    off: jest.fn(),
  },
}));

describe('useEmitter', () => {
  let wrapper;
  const eventName = 'my-event';
  const callback = jest.fn();

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

  afterEach(() => {
    jest.resetAllMocks();
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
