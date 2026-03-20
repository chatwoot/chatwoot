import { emitter } from 'shared/helpers/mitt';
import analyticsHelper from 'dashboard/helper/AnalyticsHelper';
import { useTrack, useAlert, usePendingAlert } from '../index';

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    emit: vi.fn(),
  },
}));

vi.mock('dashboard/helper/AnalyticsHelper/index', async importOriginal => {
  const actual = await importOriginal();
  actual.default = {
    track: vi.fn(),
  };
  return actual;
});

describe('useTrack', () => {
  it('should call analyticsHelper.track and return a function', () => {
    const eventArgs = ['event-name', { some: 'data' }];
    useTrack(...eventArgs);
    expect(analyticsHelper.track).toHaveBeenCalledWith(...eventArgs);
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

describe('usePendingAlert', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should emit a persistent newToastMessage and return a dismiss function', () => {
    const message = 'Adding member...';
    const dismiss = usePendingAlert(message);

    expect(emitter.emit).toHaveBeenCalledWith(
      'newToastMessage',
      expect.objectContaining({
        message,
        action: expect.objectContaining({
          persistent: true,
          key: expect.any(String),
        }),
      })
    );

    expect(typeof dismiss).toBe('function');
  });

  it('should emit dismissToastMessage with the matching key when dismiss is called', () => {
    const dismiss = usePendingAlert('Processing...');
    const emittedCall = emitter.emit.mock.calls.find(
      c => c[0] === 'newToastMessage'
    );
    const { key } = emittedCall[1].action;

    dismiss();

    expect(emitter.emit).toHaveBeenCalledWith('dismissToastMessage', { key });
  });

  it('should generate unique keys for each call', () => {
    const dismiss1 = usePendingAlert('First');
    const dismiss2 = usePendingAlert('Second');

    const calls = emitter.emit.mock.calls.filter(
      c => c[0] === 'newToastMessage'
    );
    const key1 = calls[0][1].action.key;
    const key2 = calls[1][1].action.key;

    expect(key1).not.toBe(key2);

    // Each dismiss should only dismiss its own toast
    dismiss1();
    expect(emitter.emit).toHaveBeenCalledWith('dismissToastMessage', {
      key: key1,
    });

    dismiss2();
    expect(emitter.emit).toHaveBeenCalledWith('dismissToastMessage', {
      key: key2,
    });
  });
});
