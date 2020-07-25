import { dispatchWindowEvent } from '../CustomEventHelper';

describe('dispatchWindowEvent', () => {
  it('dispatches correct event', () => {
    window.dispatchEvent = jest.fn();
    dispatchWindowEvent('chatwoot:ready');
    expect(dispatchEvent).toHaveBeenCalled();
  });
});
