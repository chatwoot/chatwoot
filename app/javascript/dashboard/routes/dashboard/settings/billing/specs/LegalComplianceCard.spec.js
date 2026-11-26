import { flushPromises, mount } from '@vue/test-utils';
import { h, KeepAlive, nextTick, ref } from 'vue';

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

const mountComponent = async (component = LegalComplianceCard) => {
  const wrapper = mount(component, {
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

const mountCachedCard = async () => {
  const billingActive = ref(true);
  const wrapper = await mountComponent({
    render: () =>
      h(KeepAlive, () => (billingActive.value ? h(LegalComplianceCard) : null)),
  });
  return { wrapper, billingActive };
};

describe('LegalComplianceCard', () => {
  beforeEach(() => {
    getLegalCompliance.mockReset();
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

  it('refreshes the signing link when returning to cached Billing', async () => {
    const { wrapper, billingActive } = await mountCachedCard();
    expect(findButton(wrapper, 'Sign DPA')).toBeDefined();
    expect(getLegalCompliance).toHaveBeenCalledTimes(1);

    billingActive.value = false;
    await nextTick();
    getLegalCompliance.mockResolvedValue({ data: { dpa_signing_url: null } });
    billingActive.value = true;
    await flushPromises();

    expect(getLegalCompliance).toHaveBeenCalledTimes(2);
    expect(findButton(wrapper, 'Sign DPA')).toBeUndefined();
    expect(findButton(wrapper, 'Trust Center')).toBeDefined();
  });

  it('ignores a signing URL returned after Billing has been left', async () => {
    let resolvePreviousRequest;
    getLegalCompliance.mockImplementationOnce(
      () =>
        new Promise(resolve => {
          resolvePreviousRequest = resolve;
        })
    );
    const { wrapper, billingActive } = await mountCachedCard();

    billingActive.value = false;
    await nextTick();
    getLegalCompliance.mockResolvedValue({ data: { dpa_signing_url: null } });
    billingActive.value = true;
    await flushPromises();
    resolvePreviousRequest({ data: { dpa_signing_url: DPA_SIGNING_URL } });
    await flushPromises();

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
