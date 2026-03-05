import NotificationSubscriptions from '../../api/notificationSubscription';
import auth from '../../api/auth';
import { useAlert } from 'dashboard/composables';
import { normalizeVapidPublicKey, registerSubscription } from '../pushHelper';

vi.mock('../../api/notificationSubscription', () => ({
  default: {
    create: vi.fn(),
  },
}));

vi.mock('../../api/auth', () => ({
  default: {
    hasAuthCookie: vi.fn(),
  },
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

describe('pushHelper', () => {
  let subscribe;
  let consoleErrorSpy;
  const waitForSubscriptionFlow = () =>
    new Promise(resolve => {
      setTimeout(resolve, 0);
    });

  const subscription = {
    endpoint: 'https://example.com/subscription',
    getKey: vi.fn(keyName =>
      keyName === 'p256dh'
        ? new Uint8Array([1, 2, 3]).buffer
        : new Uint8Array([4, 5, 6]).buffer
    ),
  };

  beforeEach(() => {
    subscribe = vi.fn().mockResolvedValue(subscription);
    window.chatwootConfig = {};

    Object.defineProperty(navigator, 'serviceWorker', {
      value: {
        ready: Promise.resolve({
          pushManager: {
            subscribe,
          },
        }),
      },
      configurable: true,
    });

    auth.hasAuthCookie.mockReturnValue(true);
    NotificationSubscriptions.create.mockResolvedValue({});
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
    vi.clearAllMocks();
  });

  it('returns Uint8Array keys as-is', () => {
    const vapidKey = new Uint8Array([10, 11, 12]);

    expect(normalizeVapidPublicKey(vapidKey)).toBe(vapidKey);
  });

  it('decodes base64url string keys', () => {
    const bytes = new Uint8Array([10, 11, 12]);
    const base64 = window
      .btoa(String.fromCharCode(...bytes))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');

    expect(normalizeVapidPublicKey(base64)).toEqual(bytes);
  });

  it('registers subscription when VAPID key is Uint8Array', async () => {
    const vapidKey = new Uint8Array([10, 11, 12]);
    const onSuccess = vi.fn();
    window.chatwootConfig = { vapidPublicKey: vapidKey };

    registerSubscription(onSuccess);
    await waitForSubscriptionFlow();

    expect(subscribe).toHaveBeenCalledWith({
      userVisibleOnly: true,
      applicationServerKey: vapidKey,
    });
    expect(NotificationSubscriptions.create).toHaveBeenCalled();
    expect(onSuccess).toHaveBeenCalled();
    expect(useAlert).not.toHaveBeenCalled();
  });

  it('shows alert when VAPID key is invalid', async () => {
    window.chatwootConfig = { vapidPublicKey: 'invalid@@@key' };

    registerSubscription();
    await waitForSubscriptionFlow();

    expect(subscribe).not.toHaveBeenCalled();
    expect(useAlert).toHaveBeenCalledWith(
      'This browser does not support desktop notification'
    );
  });
});
