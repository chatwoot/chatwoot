import { getCurrentInstance } from 'vue';
import { emitter } from 'shared/helpers/mitt';
import { useTrack, useAlert } from '../index';

vi.mock('vue', () => ({
  getCurrentInstance: vi.fn(),
}));
vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    emit: vi.fn(),
  },
}));

describe('useTrack', () => {
  it('should return a function', () => {
    const track = useTrack();
    expect(typeof track).toBe('function');
  });
});

describe('useAlert', () => {
  it('should emit a newToastMessage event with the provided message and action', () => {
    const message = 'Toast message';
    const action = {
      type: 'link',
      to: '/app/accounts/1/conversations/1',
      message: 'Navigate',
    };
    useAlert(message, action);
    expect(emitter.emit).toHaveBeenCalledWith('newToastMessage', {
      message,
      action,
    });
  });

  it('should emit a newToastMessage event with the provided message and no action if action is null', () => {
    const message = 'Toast message';
    useAlert(message);
    expect(emitter.emit).toHaveBeenCalledWith('newToastMessage', {
      message,
      action: null,
    });
  });
});
