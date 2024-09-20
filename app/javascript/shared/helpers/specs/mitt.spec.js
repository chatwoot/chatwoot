import { emitter } from '../mitt';

describe('emitter', () => {
  it('should emit and listen to events correctly', () => {
    const mockCallback = vi.fn();

    // Subscribe to an event
    emitter.on('event', mockCallback);

    // Emit the event
    emitter.emit('event', 'data');

    // Expect the callback to be called with the correct data
    expect(mockCallback).toHaveBeenCalledWith('data');

    // Unsubscribe from the event
    emitter.off('event', mockCallback);

    // Emit the event again
    emitter.emit('event', 'data');

    // Expect the callback not to be called again
    expect(mockCallback).toHaveBeenCalledTimes(1);
  });
});
