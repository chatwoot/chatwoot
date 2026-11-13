import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useImpersonation } from 'dashboard/composables/useImpersonation';
import Auth from 'dashboard/api/auth';
import { useAccountCommands } from '../useAccountCommands';

vi.mock('vue-i18n');
vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables/useImpersonation');
vi.mock('dashboard/api/auth', () => ({ default: { logout: vi.fn() } }));

describe('useAccountCommands', () => {
  let store;

  beforeEach(() => {
    store = {
      dispatch: vi.fn(),
      getters: {
        getCurrentAccountId: 1,
        getCurrentUserAvailability: 'online',
        getUserAccounts: [
          { id: 1, name: 'Acme' },
          { id: 2, name: 'Beta' },
        ],
      },
    };
    useStore.mockReturnValue(store);
    useMapGetter.mockImplementation(key => ({ value: store.getters[key] }));
    useI18n.mockReturnValue({ t: key => key });
    useImpersonation.mockReturnValue({ isImpersonating: { value: false } });
  });

  it('offers the other availability statuses', () => {
    const { accountCommands } = useAccountCommands();
    const statuses = accountCommands.value.filter(
      command => command.parent === 'set_availability'
    );

    expect(statuses.map(command => command.id)).toEqual([
      'availability-busy',
      'availability-offline',
    ]);

    statuses[0].run();
    expect(store.dispatch).toHaveBeenCalledWith('updateAvailability', {
      availability: 'busy',
      account_id: 1,
    });
  });

  it('hides availability while impersonating', () => {
    useImpersonation.mockReturnValue({ isImpersonating: { value: true } });
    const { accountCommands } = useAccountCommands();

    expect(accountCommands.value.map(command => command.id)).not.toContain(
      'set_availability'
    );
  });

  it('offers the other accounts under a switch page', () => {
    const { accountCommands } = useAccountCommands();
    const accounts = accountCommands.value.filter(
      command => command.parent === 'switch_account'
    );

    expect(accounts.map(command => command.title)).toEqual(['Beta']);
  });

  it('logs out', () => {
    const { accountCommands } = useAccountCommands();
    accountCommands.value.find(command => command.id === 'log_out').run();

    expect(Auth.logout).toHaveBeenCalled();
  });

  it('hides account switching with a single account', () => {
    store.getters.getUserAccounts = [{ id: 1, name: 'Acme' }];
    const { accountCommands } = useAccountCommands();

    expect(accountCommands.value.map(command => command.id)).not.toContain(
      'switch_account'
    );
  });
});
