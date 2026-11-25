import { shallowMount, flushPromises } from '@vue/test-utils';
import EmailBranding from '../EmailBranding.vue';

const updateAccount = vi.fn();
const dispatch = vi.fn();
const currentAccount = { value: null };

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch }),
}));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ currentAccount, updateAccount }),
}));

function montar(conta) {
  currentAccount.value = conta;
  return shallowMount(EmailBranding, {
    global: { stubs: { SectionLayout: { template: '<div><slot /></div>' } } },
  });
}

describe('EmailBranding.vue', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    updateAccount.mockResolvedValue(undefined);
    dispatch.mockResolvedValue(undefined);
  });

  it('renders without an account in the store yet', () => {
    const wrapper = montar(null);

    expect(wrapper.vm.brandName).toBe('');
    expect(wrapper.vm.logoUrl).toBeUndefined();
  });

  it('seeds the fields from the account settings', () => {
    const wrapper = montar({
      id: 1,
      settings: { brand_name: 'Café Exemplo', brand_color: '#11D135' },
      brand_logo_email_url: 'http://localhost/logo.png',
    });

    expect(wrapper.vm.brandName).toBe('Café Exemplo');
    expect(wrapper.vm.brandColor).toBe('#11D135');
    expect(wrapper.vm.logoUrl).toBe('http://localhost/logo.png');
  });

  it('saves the three text fields together', async () => {
    const wrapper = montar({ id: 1, settings: {} });
    wrapper.vm.brandName = 'Café Exemplo';
    wrapper.vm.brandUrl = 'https://www.cafe-exemplo.com.br';
    wrapper.vm.brandColor = '#11D135';

    await wrapper.vm.save();

    expect(updateAccount).toHaveBeenCalledWith({
      brand_name: 'Café Exemplo',
      brand_url: 'https://www.cafe-exemplo.com.br',
      brand_color: '#11D135',
    });
  });

  // The colour picker never emits an empty value, so without this the installation fallback
  // could not be restored from the dashboard at all.
  it('clears the colour back to the installation default', async () => {
    const wrapper = montar({ id: 1, settings: { brand_color: '#11D135' } });

    wrapper.vm.brandColor = '';
    await wrapper.vm.save();

    expect(updateAccount).toHaveBeenCalledWith(
      expect.objectContaining({ brand_color: '' })
    );
  });

  // Uploading a logo commits a fresh account to the store; a deep watcher used to take that as
  // a cue to overwrite whatever the administrator had typed and not saved.
  it('keeps unsaved edits when the account object is replaced', async () => {
    const wrapper = montar({ id: 1, settings: { brand_name: 'Antigo' } });
    wrapper.vm.brandName = 'Digitado e não salvo';

    currentAccount.value = {
      id: 1,
      settings: { brand_name: 'Antigo' },
      brand_logo_email_url: 'http://localhost/novo.png',
    };
    await flushPromises();

    expect(wrapper.vm.brandName).toBe('Digitado e não salvo');
    expect(wrapper.vm.logoUrl).toBe('http://localhost/novo.png');
  });

  it('uploads a picked logo and clears the input so the same file can be picked again', async () => {
    const wrapper = montar({ id: 1, settings: {} });
    const file = new File(['x'], 'logo.png', { type: 'image/png' });
    const target = { files: [file], value: 'C:\\fake\\logo.png' };

    await wrapper.vm.onLogoSelected({ target });

    expect(dispatch).toHaveBeenCalledWith(
      'accounts/updateBrandLogoEmail',
      file
    );
    expect(target.value).toBe('');
  });

  it('does nothing when the picker is dismissed without a file', async () => {
    const wrapper = montar({ id: 1, settings: {} });

    await wrapper.vm.onLogoSelected({ target: { files: [], value: '' } });

    expect(dispatch).not.toHaveBeenCalled();
  });

  it('removes the logo', async () => {
    const wrapper = montar({ id: 1, settings: {} });

    await wrapper.vm.removeLogo();

    expect(dispatch).toHaveBeenCalledWith('accounts/deleteBrandLogoEmail');
  });
});
