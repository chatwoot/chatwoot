import { mount, flushPromises } from '@vue/test-utils';
import McpServersAPI from 'dashboard/api/captain/mcpServers';
import ConnectMcpServerDialog from './ConnectMcpServerDialog.vue';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/api/captain/mcpServers', () => ({
  default: { discover: vi.fn(), create: vi.fn() },
}));

const DialogStub = {
  template: '<div><slot /></div>',
  methods: { open() {}, close() {} },
};

const CHECK_DELAY_MS = 500;

const mountDialog = () => {
  const wrapper = mount(ConnectMcpServerDialog, {
    props: { assistantId: 1 },
    global: { stubs: { Dialog: DialogStub, Button: true } },
  });
  wrapper.vm.open();
  return wrapper;
};

const typeAddress = (wrapper, value) =>
  wrapper.find('input[type="text"]').setValue(value);

const waitForCheck = async () => {
  await vi.advanceTimersByTimeAsync(CHECK_DELAY_MS);
  await flushPromises();
};

const tokenField = wrapper => wrapper.find('input[type="password"]');

describe('ConnectMcpServerDialog token field', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    McpServersAPI.discover.mockReset();
    McpServersAPI.discover.mockResolvedValue({
      data: { auth_type: 'token', name: 'Invoicely' },
    });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('shows the token field once the check says the server needs a token', async () => {
    const wrapper = mountDialog();

    await typeAddress(wrapper, 'mcp.example.com/mcp');
    await waitForCheck();

    expect(tokenField(wrapper).exists()).toBe(true);
  });

  it('keeps the token field when the URL is edited and changed back before the next check', async () => {
    const wrapper = mountDialog();
    await typeAddress(wrapper, 'mcp.example.com/mcp');
    await waitForCheck();

    await typeAddress(wrapper, 'mcp.example.com/mcpx');
    await typeAddress(wrapper, 'mcp.example.com/mcp');
    await waitForCheck();

    expect(tokenField(wrapper).exists()).toBe(true);
    expect(McpServersAPI.discover).toHaveBeenCalledTimes(1);
  });

  it('hides the token field while the URL is not the one that was checked', async () => {
    const wrapper = mountDialog();
    await typeAddress(wrapper, 'mcp.example.com/mcp');
    await waitForCheck();

    await typeAddress(wrapper, 'other.example.com/mcp');

    expect(tokenField(wrapper).exists()).toBe(false);
  });
});
