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
  it('should return $track from the current instance proxy', () => {
    const mockProxy = { $track: vi.fn() };
    getCurrentInstance.mockReturnValue({ proxy: mockProxy });
    const track = useTrack();
    expect(track).toBe(mockProxy.$track);
  });

  it('should throw an error if called outside of setup', () => {
    getCurrentInstance.mockReturnValue(null);
    expect(useTrack).toThrowError('must be called in setup');
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
