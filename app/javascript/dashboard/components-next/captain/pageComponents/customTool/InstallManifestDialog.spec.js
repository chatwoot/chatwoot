import { flushPromises, mount } from '@vue/test-utils';
import InstallManifestDialog from './InstallManifestDialog.vue';

const mocks = vi.hoisted(() => ({
  preview: vi.fn(),
  install: vi.fn(),
  alert: vi.fn(),
  dialogClose: vi.fn(),
}));

vi.mock('dashboard/api/captain/toolsManifest', () => ({
  default: { preview: mocks.preview, install: mocks.install },
}));
vi.mock('dashboard/composables', () => ({ useAlert: mocks.alert }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));

const DialogStub = {
  emits: ['confirm'],
  methods: {
    open() {},
    close() {
      mocks.dialogClose();
    },
  },
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
  await wrapper.find('input').setValue(' Chatwoot/Support-Tools/Shopify ');
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
      // Sent as entered: the preview's identity is lowercase, but GitHub folder names are case-sensitive
      source: 'Chatwoot/Support-Tools/Shopify',
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

  it('locks the dialog while installing and ignores results from a previous session', async () => {
    let finishInstall;
    mocks.install.mockReturnValue(
      new Promise(resolve => {
        finishInstall = resolve;
      })
    );
    const wrapper = mountDialog();
    await loadPreview(wrapper, previewData);
    await wrapper.find('input[type="password"]').setValue('shpat_secret');
    await wrapper.findAll('button').at(-1).trigger('click');

    expect(
      wrapper.findAll('button').at(0).attributes('disabled')
    ).toBeDefined();

    wrapper.vm.open();
    finishInstall({ data: { payload: [] } });
    await flushPromises();

    expect(wrapper.emitted('installed')).toHaveLength(1);
    expect(mocks.dialogClose).not.toHaveBeenCalled();
    expect(mocks.alert).not.toHaveBeenCalled();
  });

  it('does not treat built-in object property names as filled', async () => {
    const wrapper = mountDialog();
    await loadPreview(wrapper, {
      ...previewData,
      fields: [
        {
          name: 'constructor',
          section: 'inputs',
          label: 'Store',
          type: 'string',
          placeholder: null,
          required: true,
          options: null,
        },
      ],
    });

    expect(
      wrapper.findAll('button').at(-1).attributes('disabled')
    ).toBeDefined();
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
