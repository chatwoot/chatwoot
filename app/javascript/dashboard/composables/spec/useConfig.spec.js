import { ref } from 'vue';
import { useConfig } from '../useConfig';

vi.mock('../useConfig', () => ({
  useConfig: vi.fn(),
}));

describe('useConfig', () => {
  beforeEach(() => {
    useConfig.mockReturnValue({
      hostURL: ref('https://example.com'),
      vapidPublicKey: ref('vapid-key'),
      enabledLanguages: ref(['en', 'fr']),
      isEnterprise: ref(true),
      enterprisePlanName: ref('enterprise'),
    });
  });

  it('returns the correct hostURL', () => {
    const { hostURL } = useConfig();
    expect(hostURL.value).toBe('https://example.com');
  });

  it('returns the correct vapidPublicKey', () => {
    const { vapidPublicKey } = useConfig();
    expect(vapidPublicKey.value).toBe('vapid-key');
  });

  it('returns the correct enabledLanguages', () => {
    const { enabledLanguages } = useConfig();
    expect(enabledLanguages.value).toEqual(['en', 'fr']);
  });

  it('returns the correct isEnterprise value', () => {
    const { isEnterprise } = useConfig();
    expect(isEnterprise.value).toBe(true);
  });

  it('returns the correct enterprisePlanName', () => {
    const { enterprisePlanName } = useConfig();
    expect(enterprisePlanName.value).toBe('enterprise');
  });

  it('handles missing config values', () => {
    useConfig.mockReturnValue({
      hostURL: ref(undefined),
      vapidPublicKey: ref(undefined),
      enabledLanguages: ref(undefined),
      isEnterprise: ref(false),
      enterprisePlanName: ref(undefined),
    });

    const {
      hostURL,
      vapidPublicKey,
      enabledLanguages,
      isEnterprise,
      enterprisePlanName,
    } = useConfig();

    expect(hostURL.value).toBeUndefined();
    expect(vapidPublicKey.value).toBeUndefined();
    expect(enabledLanguages.value).toBeUndefined();
    expect(isEnterprise.value).toBe(false);
    expect(enterprisePlanName.value).toBeUndefined();
  });
});
