import Settings from '../Settings.vue';
import InboxHealthAPI from 'dashboard/api/inboxHealth';
import { useAlert } from 'dashboard/composables';

vi.mock('dashboard/api/inboxHealth', () => ({
  default: { applyDisplayName: vi.fn() },
}));
vi.mock('dashboard/composables', async importOriginal => ({
  ...(await importOriginal()),
  useAlert: vi.fn(),
}));

describe('Inbox settings display name activation', () => {
  const createContext = () => ({
    inbox: { id: 377 },
    isApplyingDisplayName: false,
    healthError: null,
    healthData: { verified_name: 'Mona', name_status: 'DECLINED' },
    fetchHealthData: vi.fn(),
    $t: key => key,
  });

  beforeEach(() => {
    vi.clearAllMocks();
    InboxHealthAPI.applyDisplayName.mockResolvedValue({
      data: { registration_submitted: true },
    });
  });

  it('reports activation only after the health refresh confirms the exact name', async () => {
    const context = createContext();
    context.fetchHealthData.mockImplementation(async () => {
      context.healthData = {
        verified_name: 'Mona Assistant',
        name_status: 'APPROVED',
      };
    });
    await Settings.methods.applyDisplayName.call(context, 'Mona Assistant');
    expect(InboxHealthAPI.applyDisplayName).toHaveBeenCalledWith(
      377,
      'Mona Assistant'
    );
    expect(useAlert).toHaveBeenCalledWith(
      'INBOX_MGMT.ACCOUNT_HEALTH.DISPLAY_NAME.SUCCESS'
    );
    expect(context.isApplyingDisplayName).toBe(false);
  });

  it('reports acceptance instead of activation when Meta still returns the old name', async () => {
    const context = createContext();
    await Settings.methods.applyDisplayName.call(context, 'Mona Assistant');
    expect(useAlert).toHaveBeenCalledWith(
      'INBOX_MGMT.ACCOUNT_HEALTH.DISPLAY_NAME.SUBMITTED'
    );
  });

  it('reports acceptance when the verification refresh fails', async () => {
    const context = createContext();
    context.fetchHealthData.mockImplementation(async () => {
      context.healthError = { message: 'Meta unavailable' };
    });
    await Settings.methods.applyDisplayName.call(context, 'Mona Assistant');
    expect(useAlert).toHaveBeenCalledWith(
      'INBOX_MGMT.ACCOUNT_HEALTH.DISPLAY_NAME.SUBMITTED'
    );
  });

  it('handles provider failure followed by a successful attempt without retaining busy state', async () => {
    const context = createContext();
    InboxHealthAPI.applyDisplayName.mockRejectedValueOnce({
      response: { data: { error: 'Invalid PIN' } },
    });
    await Settings.methods.applyDisplayName.call(context, 'Mona Assistant');
    expect(useAlert).toHaveBeenLastCalledWith('Invalid PIN');
    expect(context.fetchHealthData).not.toHaveBeenCalled();
    expect(context.isApplyingDisplayName).toBe(false);
    context.fetchHealthData.mockImplementation(async () => {
      context.healthData = {
        verified_name: 'Mona Assistant',
        name_status: 'APPROVED',
      };
    });
    await Settings.methods.applyDisplayName.call(context, 'Mona Assistant');
    expect(useAlert).toHaveBeenLastCalledWith(
      'INBOX_MGMT.ACCOUNT_HEALTH.DISPLAY_NAME.SUCCESS'
    );
    expect(InboxHealthAPI.applyDisplayName).toHaveBeenCalledTimes(2);
  });

  it('does not submit again while an attempt is in flight', async () => {
    const context = { ...createContext(), isApplyingDisplayName: true };
    await Settings.methods.applyDisplayName.call(context, 'Mona Assistant');
    expect(InboxHealthAPI.applyDisplayName).not.toHaveBeenCalled();
  });

  it('does not refresh or announce success for a different inbox after navigation', async () => {
    const context = createContext();
    InboxHealthAPI.applyDisplayName.mockImplementationOnce(async () => {
      context.inbox = { id: 378 };
    });
    await Settings.methods.applyDisplayName.call(context, 'Mona Assistant');
    expect(context.fetchHealthData).not.toHaveBeenCalled();
    expect(useAlert).not.toHaveBeenCalled();
    expect(context.isApplyingDisplayName).toBe(false);
  });
});
