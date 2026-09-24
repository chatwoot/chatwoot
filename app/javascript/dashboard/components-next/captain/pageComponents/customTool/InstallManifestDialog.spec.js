import { flushPromises, mount } from '@vue/test-utils';
import InstallManifestDialog from './InstallManifestDialog.vue';

const mocks = vi.hoisted(() => ({
  preview: vi.fn(),
  install: vi.fn(),
  alert: vi.fn(),
}));

vi.mock('dashboard/api/captain/toolsManifest', () => ({
  default: { preview: mocks.preview, install: mocks.install },
}));
vi.mock('dashboard/composables', () => ({ useAlert: mocks.alert }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

const DialogStub = {
  emits: ['confirm'],
  methods: { open() {}, close() {} },
  template: '<div><slot /><slot name="footer" /></div>',
};

const previewData = {
  name: 'Shopify Support Tools',
  description: 'Look up Shopify orders.',
  version: '1.2.0',
  repository: 'chatwoot/support-tools',
  path: 'shopify',
  revision: 'a'.repeat(40),
  installed_revision: null,
  up_to_date: false,
  fields: [
    {
      name: 'access_token',
      section: 'secrets',
      label: 'Access token',
      type: 'password',
      placeholder: null,
      required: true,
      options: null,
    },
  ],
  tools: [
    {
      id: 'get_order',
      title: 'Get Order',
      description: 'Retrieve an order',
      http_method: 'GET',
    },
  ],
};

const mountDialog = () =>
  mount(InstallManifestDialog, {
    props: { assistantId: 7 },
    global: { stubs: { Dialog: DialogStub } },
  });

const loadPreview = async (wrapper, data) => {
  mocks.preview.mockResolvedValue({ data });
  await wrapper
    .find('input')
    .setValue('https://github.com/chatwoot/support-tools/tree/main/shopify');
  await wrapper.findAll('button').at(-1).trigger('click');
  await flushPromises();
};

describe('InstallManifestDialog', () => {
  beforeEach(() => vi.clearAllMocks());

  it('installs the previewed toolset with the entered values', async () => {
    mocks.install.mockResolvedValue({ data: { payload: [] } });
    const wrapper = mountDialog();
    await loadPreview(wrapper, previewData);

    const installButton = wrapper.findAll('button').at(-1);
    expect(installButton.attributes('disabled')).toBeDefined();

    await wrapper.find('input[type="password"]').setValue('shpat_secret');
    await installButton.trigger('click');
    await flushPromises();

    expect(mocks.install).toHaveBeenCalledWith({
      assistantId: 7,
      source: 'chatwoot/support-tools/shopify',
      revision: previewData.revision,
      configuration: { inputs: {}, secrets: { access_token: 'shpat_secret' } },
    });
    expect(wrapper.emitted('installed')).toHaveLength(1);
  });

  it('cancels a pending preview when the dialog closes', async () => {
    let previewSignal;
    mocks.preview.mockImplementation((_, { signal }) => {
      previewSignal = signal;
      return new Promise(() => {});
    });
    const wrapper = mountDialog();
    await wrapper.find('input').setValue('chatwoot/support-tools/shopify');
    await wrapper.findAll('button').at(-1).trigger('click');

    wrapper.findComponent(DialogStub).vm.$emit('close');

    expect(previewSignal.aborted).toBe(true);
  });

  it('disables installing when the latest commit is already installed', async () => {
    const wrapper = mountDialog();
    await loadPreview(wrapper, {
      ...previewData,
      installed_revision: previewData.revision,
      up_to_date: true,
    });

    const installButton = wrapper.findAll('button').at(-1);
    expect(installButton.text()).toContain(
      'CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.ALREADY_INSTALLED'
    );
    expect(installButton.attributes('disabled')).toBeDefined();
  });

  it('offers a reinstall when tools are missing at the installed commit', async () => {
    const wrapper = mountDialog();
    await loadPreview(wrapper, {
      ...previewData,
      installed_revision: previewData.revision,
      up_to_date: false,
    });
    await wrapper.find('input[type="password"]').setValue('shpat_secret');

    const installButton = wrapper.findAll('button').at(-1);
    expect(installButton.text()).toContain(
      'CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.REINSTALL'
    );
    expect(installButton.attributes('disabled')).toBeUndefined();
    expect(wrapper.text()).toContain(
      'CAPTAIN.CUSTOM_TOOLS.INSTALL_MANIFEST.REINSTALL_NOTE'
    );
  });
});
