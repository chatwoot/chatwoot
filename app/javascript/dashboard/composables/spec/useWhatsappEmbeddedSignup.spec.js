import { useWhatsappEmbeddedSignup } from '../useWhatsappEmbeddedSignup';
import {
  setupFacebookSdk,
  initWhatsAppEmbeddedSignup,
  createMessageHandler,
} from 'dashboard/routes/dashboard/settings/inbox/channels/whatsapp/utils';

// The event classifier is exercised through the composable rather than stubbed, so
// these specs cover the real v3/v4 event-name handling.
vi.mock(
  'dashboard/routes/dashboard/settings/inbox/channels/whatsapp/utils',
  async importOriginal => ({
    ...(await importOriginal()),
    setupFacebookSdk: vi.fn(),
    initWhatsAppEmbeddedSignup: vi.fn(),
    createMessageHandler: vi.fn(),
  })
);

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

const flushPromises = () =>
  new Promise(resolve => {
    setTimeout(resolve, 0);
  });

const createDeferred = () => {
  let resolve;
  let reject;
  const promise = new Promise((res, rej) => {
    resolve = res;
    reject = rej;
  });
  return { promise, resolve, reject };
};

const VALID_BUSINESS = {
  business_id: 'biz-1',
  waba_id: 'waba-1',
  phone_number_id: 'phone-1',
};

describe('useWhatsappEmbeddedSignup', () => {
  // The mocked createMessageHandler captures the callback the composable
  // registers, so tests can simulate Meta's WA_EMBEDDED_SIGNUP postMessages
  // directly without the window-event + origin plumbing (that is covered by
  // the utils' own tests).
  let signupCallback;
  let registeredListener;

  const emit = data => signupCallback(data);

  beforeEach(() => {
    vi.clearAllMocks();

    window.chatwootConfig = {
      whatsappAppId: 'app-id',
      whatsappConfigurationId: 'config-id',
      whatsappApiVersion: 'v22.0',
    };

    setupFacebookSdk.mockResolvedValue();
    createMessageHandler.mockImplementation(callback => {
      signupCallback = callback;
      registeredListener = () => {};
      return registeredListener;
    });
  });

  it('resolves credentials when the auth code arrives before the business data', async () => {
    initWhatsAppEmbeddedSignup.mockResolvedValue('auth-code');

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();
    const result = runEmbeddedSignup();

    await flushPromises(); // SDK setup + FB.login resolve the code first
    emit({ event: 'FINISH', data: VALID_BUSINESS });

    await expect(result).resolves.toEqual({
      code: 'auth-code',
      business_id: 'biz-1',
      waba_id: 'waba-1',
      phone_number_id: 'phone-1',
      is_coexistence: false,
    });
    expect(setupFacebookSdk).toHaveBeenCalledWith('app-id', 'v22.0');
    expect(initWhatsAppEmbeddedSignup).toHaveBeenCalledWith('config-id');
  });

  it('resolves credentials when the business data arrives before the auth code', async () => {
    const code = createDeferred();
    initWhatsAppEmbeddedSignup.mockReturnValue(code.promise);

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();
    const result = runEmbeddedSignup();

    // Business data lands first, while FB.login is still pending.
    emit({
      event: 'FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING',
      data: VALID_BUSINESS,
    });
    code.resolve('late-code');

    await expect(result).resolves.toEqual({
      code: 'late-code',
      business_id: 'biz-1',
      waba_id: 'waba-1',
      phone_number_id: 'phone-1',
      is_coexistence: true,
    });
  });

  it('resolves a coexistence completion that only carries waba_id', async () => {
    initWhatsAppEmbeddedSignup.mockResolvedValue('auth-code');

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();
    const result = runEmbeddedSignup();

    await flushPromises();
    emit({
      event: 'FINISH_WHATSAPP_BUSINESS_APP_ONBOARDING',
      data: { waba_id: 'waba-1' },
    });

    await expect(result).resolves.toEqual({
      code: 'auth-code',
      business_id: '',
      waba_id: 'waba-1',
      phone_number_id: '',
      is_coexistence: true,
    });
  });

  it('defaults phone_number_id to an empty string when absent', async () => {
    initWhatsAppEmbeddedSignup.mockResolvedValue('auth-code');

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();
    const result = runEmbeddedSignup();

    await flushPromises();
    emit({
      event: 'FINISH',
      data: { business_id: 'biz-1', waba_id: 'waba-1' },
    });

    await expect(result).resolves.toMatchObject({ phone_number_id: '' });
  });

  it('resolves null when FB.login is cancelled', async () => {
    initWhatsAppEmbeddedSignup.mockRejectedValue(new Error('Login cancelled'));

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();

    await expect(runEmbeddedSignup()).resolves.toBeNull();
  });

  it('resolves null on a CANCEL event', async () => {
    initWhatsAppEmbeddedSignup.mockReturnValue(createDeferred().promise);

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();
    const result = runEmbeddedSignup();

    emit({ event: 'CANCEL' });

    await expect(result).resolves.toBeNull();
  });

  it.each(['error', 'ERROR'])(
    'rejects with the Meta error message on a %s event',
    async event => {
      initWhatsAppEmbeddedSignup.mockReturnValue(createDeferred().promise);

      const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();
      const result = runEmbeddedSignup();

      emit({ event, error_message: 'WABA not eligible' });

      await expect(result).rejects.toThrow('WABA not eligible');
    }
  );

  it('rejects a CANCEL that carries an error message rather than treating it as a dismissal', async () => {
    initWhatsAppEmbeddedSignup.mockReturnValue(createDeferred().promise);

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();
    const result = runEmbeddedSignup();

    emit({ event: 'CANCEL', error_message: 'Phone number already in use' });

    await expect(result).rejects.toThrow('Phone number already in use');
  });

  it.each([
    'FINISH_ONLY_WABA',
    'FINISH_OBO_MIGRATION',
    'FINISH_GRANT_ONLY_API_ACCESS',
  ])('rejects the %s completion instead of hanging', async event => {
    initWhatsAppEmbeddedSignup.mockReturnValue(createDeferred().promise);

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();
    const result = runEmbeddedSignup();

    emit({ event, data: { waba_id: 'waba-1' } });

    await expect(result).rejects.toThrow(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.UNSUPPORTED_COMPLETION'
    );
  });

  it('stays pending on a non-terminal event', async () => {
    initWhatsAppEmbeddedSignup.mockResolvedValue('auth-code');

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();
    const result = runEmbeddedSignup();
    const pending = Symbol('pending');

    await flushPromises();
    emit({ event: 'SOMETHING_ELSE', current_step: 'PHONE_NUMBER_SELECTION' });

    await expect(
      Promise.race([result, Promise.resolve(pending)])
    ).resolves.toBe(pending);

    // Let the run finish so it doesn't leak into the next test.
    emit({ event: 'FINISH', data: VALID_BUSINESS });
    await result;
  });

  it('rejects when the business data is invalid', async () => {
    initWhatsAppEmbeddedSignup.mockReturnValue(createDeferred().promise);

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();
    const result = runEmbeddedSignup();

    emit({ event: 'FINISH', data: { business_id: 'biz-1' } }); // no waba_id

    await expect(result).rejects.toThrow(
      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.INVALID_BUSINESS_DATA'
    );
  });

  it('rejects when the SDK or login fails for a non-cancel reason', async () => {
    initWhatsAppEmbeddedSignup.mockRejectedValue(new Error('popup blocked'));

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();

    await expect(runEmbeddedSignup()).rejects.toThrow('popup blocked');
  });

  it('ignores a second call while a run is in flight', async () => {
    initWhatsAppEmbeddedSignup.mockResolvedValue('auth-code');

    const { runEmbeddedSignup } = useWhatsappEmbeddedSignup();
    const first = runEmbeddedSignup();
    const second = runEmbeddedSignup();

    await expect(second).resolves.toBeNull();

    // Let the first run finish so it doesn't leak into the next test.
    await flushPromises();
    emit({ event: 'FINISH', data: VALID_BUSINESS });
    await first;

    expect(setupFacebookSdk).toHaveBeenCalledTimes(1);
  });

  it('toggles isAuthenticating and removes the listener once settled', async () => {
    initWhatsAppEmbeddedSignup.mockResolvedValue('auth-code');
    const removeSpy = vi.spyOn(window, 'removeEventListener');

    const { isAuthenticating, runEmbeddedSignup } = useWhatsappEmbeddedSignup();
    expect(isAuthenticating.value).toBe(false);

    const result = runEmbeddedSignup();
    expect(isAuthenticating.value).toBe(true);

    await flushPromises();
    emit({ event: 'FINISH', data: VALID_BUSINESS });
    await result;

    expect(isAuthenticating.value).toBe(false);
    expect(removeSpy).toHaveBeenCalledWith('message', registeredListener);
    removeSpy.mockRestore();
  });
});
