import ApiClient from '../ApiClient';
import whatsappInteractivePresetsAPI from '../whatsappInteractivePresets';

describe('#WhatsAppInteractivePresetsAPI', () => {
  const originalAxios = window.axios;
  const axiosMock = { get: vi.fn() };

  beforeEach(() => {
    window.axios = axiosMock;
    window.history.pushState({}, '', '/app/accounts/42/dashboard');
  });

  afterEach(() => {
    window.axios = originalAxios;
    vi.clearAllMocks();
  });

  it('is account scoped and encodes literal search text', () => {
    expect(whatsappInteractivePresetsAPI).toBeInstanceOf(ApiClient);

    whatsappInteractivePresetsAPI.get({ search: 'save 100% & go' });

    expect(axiosMock.get).toHaveBeenCalledWith(
      '/api/v1/accounts/42/whatsapp_interactive_presets?search=save%20100%25%20%26%20go'
    );
  });

  it('uses the flat collection URL for a blank search', () => {
    whatsappInteractivePresetsAPI.get({ search: '  ' });

    expect(axiosMock.get).toHaveBeenCalledWith(
      '/api/v1/accounts/42/whatsapp_interactive_presets'
    );
  });
});
