import { mount, flushPromises } from '@vue/test-utils';
import McpServersAPI from 'dashboard/api/captain/mcpServers';
import ManageMcpServerPanel from './ManageMcpServerPanel.vue';
import McpToolsStep from './McpToolsStep.vue';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/api/captain/mcpServers', () => ({
  default: { liveTools: vi.fn(), approveTool: vi.fn(), update: vi.fn() },
}));

const SidePanelStub = {
  template: '<div><slot /><slot name="footer" /></div>',
  methods: { open() {}, close() {} },
};

const approvedTool = name => ({
  name,
  description: `${name} description`,
  input_schema: { type: 'object', properties: {} },
  approved_digest: `${name}-digest`,
  param_sources: {},
  settings: {},
  enabled: true,
});

const server = {
  id: 1,
  name: 'Invoicely',
  url: 'https://mcp.example.com/mcp',
  auth_type: 'none',
  tools: [approvedTool('get_customer'), approvedTool('refund_invoice')],
};

const liveTool = (name, changed = false) => ({
  name,
  description: `${name} description`,
  input_schema: { type: 'object', properties: {} },
  digest: `${name}-digest`,
  approved: true,
  changed,
});

describe('ManageMcpServerPanel', () => {
  beforeEach(() => {
    McpServersAPI.liveTools.mockResolvedValue({
      data: {
        payload: [liveTool('get_customer'), liveTool('refund_invoice', true)],
        missing: [],
      },
    });
    McpServersAPI.approveTool.mockResolvedValue({ data: server });
  });

  it('keeps unsaved tool choices when an admin approves another tool’s change', async () => {
    const wrapper = mount(ManageMcpServerPanel, {
      props: { assistantId: 1 },
      global: {
        stubs: {
          SidePanel: SidePanelStub,
          Button: true,
          McpStepper: true,
          McpToolsStep: true,
        },
      },
    });
    wrapper.vm.open(server);
    await flushPromises();
    const toolsStep = wrapper.findComponent(McpToolsStep);
    expect(toolsStep.props('selectedNames')).toEqual([
      'get_customer',
      'refund_invoice',
    ]);

    toolsStep.vm.$emit('toggle', 'get_customer', false);
    toolsStep.vm.$emit('approve', liveTool('refund_invoice', true));
    await flushPromises();

    expect(McpServersAPI.approveTool).toHaveBeenCalled();
    expect(McpServersAPI.liveTools).toHaveBeenCalledTimes(2);
    expect(wrapper.findComponent(McpToolsStep).props('selectedNames')).toEqual([
      'refund_invoice',
    ]);
  });
});
