import Settings from '../Settings.vue';
import InboxHealthAPI from 'dashboard/api/inboxHealth';

vi.mock('dashboard/api/inboxHealth', () => ({
  default: { registerWebhook: vi.fn(), getHealthStatus: vi.fn() },
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

// The method is exercised on its own rather than through a mount: this page pulls the whole inbox
// settings screen in, and what is under test is one branch of one method.
describe('Settings registerWebhook', () => {
  const contextWith = overrides => ({
    inbox: { id: 7 },
    isRegisteringWebhook: false,
    healthData: null,
    healthError: { type: 'api', message: 'Net::ReadTimeout' },
    $t: key => key,
    fetchHealthData: vi.fn(),
    ...overrides,
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // Registering from the error state is what #593 made possible, so this branch is the first that
  // can be reached while an error is on the screen. Leaving it set would keep the error card over a
  // reading that came back, with the button still offered for a webhook that is already registered.
  it('clears the error when the registration answers with the routing it read back', async () => {
    InboxHealthAPI.registerWebhook.mockResolvedValue({
      data: { routing_read_back: true, health: { status: 'CONNECTED' } },
    });
    const context = contextWith({});

    await Settings.methods.registerWebhook.call(context);

    expect(context.healthData).toEqual({ status: 'CONNECTED' });
    expect(context.healthError).toBeNull();
    expect(context.fetchHealthData).not.toHaveBeenCalled();
  });

  it('falls back to a fresh read when the answer did not carry the routing', async () => {
    InboxHealthAPI.registerWebhook.mockResolvedValue({
      data: { routing_read_back: false },
    });
    const context = contextWith({});

    await Settings.methods.registerWebhook.call(context);

    expect(context.fetchHealthData).toHaveBeenCalled();
  });

  it('leaves the error alone when the registration itself failed', async () => {
    InboxHealthAPI.registerWebhook.mockRejectedValue(new Error('boom'));
    const context = contextWith({});

    await Settings.methods.registerWebhook.call(context);

    expect(context.healthError).toEqual({
      type: 'api',
      message: 'Net::ReadTimeout',
    });
    expect(context.isRegisteringWebhook).toBe(false);
  });
});

describe('Settings fetchHealthData', () => {
  const contextWith = overrides => ({
    inbox: { id: 7 },
    isAWhatsAppCloudChannel: true,
    isLoadingHealth: false,
    healthData: null,
    healthError: { type: 'api', message: 'Net::ReadTimeout' },
    ...overrides,
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  // Clearing the error before asking drops the screen into the "nothing is known" state for the
  // length of the read, which with a quiet Meta is the whole ceiling. Nobody could see that gap
  // until #593 put a control in the error state for the operator to press.
  it('keeps the error on the screen while the re-read is in flight', async () => {
    let answer;
    InboxHealthAPI.getHealthStatus.mockReturnValue(
      new Promise(resolve => {
        answer = resolve;
      })
    );
    const context = contextWith({});

    const pending = Settings.methods.fetchHealthData.call(context);

    expect(context.healthError).not.toBeNull();
    expect(context.healthData).toBeNull();

    answer({ data: { status: 'CONNECTED' } });
    await pending;

    expect(context.healthError).toBeNull();
    expect(context.healthData).toEqual({ status: 'CONNECTED' });
  });

  it('replaces the error when the re-read fails too', async () => {
    InboxHealthAPI.getHealthStatus.mockRejectedValue(new Error('still quiet'));
    const context = contextWith({});

    await Settings.methods.fetchHealthData.call(context);

    expect(context.healthError).toEqual({
      type: 'generic',
      message: 'still quiet',
    });
  });
});
