import { flushPromises, mount } from '@vue/test-utils';

import LegalComplianceCard from '../components/LegalComplianceCard.vue';

const DPA_SIGNING_URL = 'https://app.hellosign.com/s/example';

const { getLegalCompliance } = vi.hoisted(() => ({
  getLegalCompliance: vi.fn(),
}));

vi.mock('dashboard/api/enterprise/account', () => ({
  default: { getLegalCompliance },
}));

vi.mock('shared/composables/useBranding', () => ({
  useBranding: () => ({
    replaceInstallationName: text => text.replace(/chatwoot/gi, 'Acme'),
  }),
}));

const translations = {
  'BILLING_SETTINGS.LEGAL_COMPLIANCE.TITLE': 'Legal & Compliance',
  'BILLING_SETTINGS.LEGAL_COMPLIANCE.DPA.DESCRIPTION':
    'Sign a Data Processing Agreement between your organization and Chatwoot.',
  'BILLING_SETTINGS.LEGAL_COMPLIANCE.DPA.BUTTON_TXT': 'Sign DPA',
  'BILLING_SETTINGS.LEGAL_COMPLIANCE.TRUST_CENTER.BUTTON_TXT': 'Trust Center',
};

const mountComponent = async () => {
  const wrapper = mount(LegalComplianceCard, {
    global: {
      mocks: {
        $t: key => translations[key] || key,
      },
    },
  });
  await flushPromises();
  return wrapper;
};

const findButton = (wrapper, label) =>
  wrapper.findAll('button').find(button => button.text() === label);

describe('LegalComplianceCard', () => {
  beforeEach(() => {
    getLegalCompliance.mockResolvedValue({
      data: { dpa_signing_url: DPA_SIGNING_URL },
    });
    vi.spyOn(window, 'open').mockImplementation(() => null);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('uses the installation name in the DPA description', async () => {
    const wrapper = await mountComponent();

    expect(wrapper.text()).toContain('Legal & Compliance');
    expect(wrapper.text()).toContain(
      'Sign a Data Processing Agreement between your organization and Acme.'
    );
  });

  it('opens the DPA signing link from the API in a new tab', async () => {
    const wrapper = await mountComponent();

    await findButton(wrapper, 'Sign DPA').trigger('click');

    expect(window.open).toHaveBeenCalledWith(
      DPA_SIGNING_URL,
      '_blank',
      'noopener,noreferrer'
    );
  });

  it('hides the DPA row when no signing link is configured', async () => {
    getLegalCompliance.mockResolvedValue({ data: { dpa_signing_url: null } });

    const wrapper = await mountComponent();

    expect(findButton(wrapper, 'Sign DPA')).toBeUndefined();
    expect(findButton(wrapper, 'Trust Center')).toBeDefined();
  });

  it('hides the DPA row when the request fails', async () => {
    getLegalCompliance.mockRejectedValue(new Error('Not found'));

    const wrapper = await mountComponent();

    expect(findButton(wrapper, 'Sign DPA')).toBeUndefined();
  });

  it('opens the Trust Center in a new tab', async () => {
    const wrapper = await mountComponent();

    await findButton(wrapper, 'Trust Center').trigger('click');

    expect(window.open).toHaveBeenCalledWith(
      'https://trust.chatwoot.com',
      '_blank',
      'noopener,noreferrer'
    );
  });
});
