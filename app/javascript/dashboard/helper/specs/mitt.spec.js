import bus from '../mitt';

describe('bus', () => {
  it('should emit and receive events', () => {
    const eventHandler = jest.fn();
    bus.$on('myEvent', eventHandler);
    bus.$emit('myEvent', 'Hello, World!');
    expect(eventHandler).toHaveBeenCalledWith('Hello, World!');
    bus.$off('myEvent', eventHandler);
    bus.$emit('myEvent', 'Goodbye, World!');
    expect(eventHandler).toHaveBeenCalledTimes(1);
  });
});
