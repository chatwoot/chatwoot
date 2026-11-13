import { flushPromises, mount } from '@vue/test-utils';
import AccountPicker from '../AccountPicker.vue';
import instagramClient from 'dashboard/api/channel/instagramClient';

vi.mock('dashboard/api/channel/instagramClient', () => ({
  default: { fetchAccounts: vi.fn(), connectAccount: vi.fn() },
}));

const accounts = [
  { id: 'ig1', username: 'first' },
  { id: 'ig2', username: 'second' },
];

const mountPicker = () =>
  mount(AccountPicker, {
    props: { connectionToken: 'pending-connection' },
    global: { stubs: { Icon: true, Spinner: true } },
  });

describe('Instagram AccountPicker', () => {
  beforeEach(() => {
    Object.defineProperty(window, 'location', {
      configurable: true,
      value: { href: '' },
      writable: true,
    });
    instagramClient.connectAccount.mockResolvedValue({
      data: { redirect_url: '/app/accounts/1/settings/inboxes/new/42/agents' },
    });
  });

  it('connects a single shared account automatically', async () => {
    instagramClient.fetchAccounts.mockResolvedValue({
      data: { accounts: [accounts[0]] },
    });
    mountPicker();
    await flushPromises();

    expect(instagramClient.connectAccount).toHaveBeenCalledWith(
      'pending-connection',
      'ig1'
    );
    expect(window.location.href).toBe(
      '/app/accounts/1/settings/inboxes/new/42/agents'
    );
  });

  it('waits for an explicit choice when multiple accounts are shared', async () => {
    instagramClient.fetchAccounts.mockResolvedValue({ data: { accounts } });
    const wrapper = mountPicker();
    await flushPromises();

    expect(instagramClient.connectAccount).not.toHaveBeenCalled();
    await wrapper.find('select').setValue('ig2');
    await wrapper.find('button').trigger('click');
    await flushPromises();

    expect(instagramClient.connectAccount).toHaveBeenCalledWith(
      'pending-connection',
      'ig2'
    );
  });

  it('shows an expired connection error and lets the user start again', async () => {
    instagramClient.fetchAccounts.mockRejectedValue({
      response: { data: { error: 'Connection expired' } },
    });
    const wrapper = mountPicker();
    await flushPromises();

    expect(wrapper.find('[role="alert"]').text()).toBe('Connection expired');
    await wrapper.findAll('button').at(-1).trigger('click');
    expect(wrapper.emitted('cancel')).toHaveLength(1);
    expect(instagramClient.connectAccount).not.toHaveBeenCalled();
  });

  it('keeps the account available for retry when subscription fails', async () => {
    instagramClient.fetchAccounts.mockResolvedValue({
      data: { accounts: [accounts[0]] },
    });
    instagramClient.connectAccount.mockRejectedValue({
      response: { data: { error: 'Permission denied' } },
    });
    const wrapper = mountPicker();
    await flushPromises();

    expect(wrapper.find('[role="alert"]').text()).toBe('Permission denied');
    expect(wrapper.find('button').attributes('disabled')).toBeUndefined();
    expect(window.location.href).toBe('');
  });
});
