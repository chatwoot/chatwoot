import { useConfig } from '../useConfig';

describe('useConfig', () => {
  const originalChatwootConfig = window.chatwootConfig;

  beforeEach(() => {
    window.chatwootConfig = {
      hostURL: 'https://example.com',
      vapidPublicKey: 'vapid-key',
      enabledLanguages: ['en', 'fr'],
      isEnterprise: 'true',
      enterprisePlanName: 'enterprise',
    };
  });

  afterEach(() => {
    window.chatwootConfig = originalChatwootConfig;
  });

  it('returns the correct configuration values', () => {
    const config = useConfig();

    expect(config.hostURL).toBe('https://example.com');
    expect(config.vapidPublicKey).toBe('vapid-key');
    expect(config.enabledLanguages).toEqual(['en', 'fr']);
    expect(config.isEnterprise).toBe(true);
    expect(config.enterprisePlanName).toBe('enterprise');
  });

  it('handles missing configuration values', () => {
    window.chatwootConfig = {};
    const config = useConfig();

    expect(config.hostURL).toBeUndefined();
    expect(config.vapidPublicKey).toBeUndefined();
    expect(config.enabledLanguages).toBeUndefined();
    // -------------- Reason ---------------
    // isEnterprise is now hardcoded to true in useConfig.js
    // ------------ Original -----------------------
    // expect(config.isEnterprise).toBe(false);
    // ---------------------------------------------
    // ---------------------- Modification Begin ----------------------
    expect(config.isEnterprise).toBe(true);
    // ---------------------- Modification End ------------------------
    expect(config.enterprisePlanName).toBeUndefined();
  });

  it('handles undefined window.chatwootConfig', () => {
    window.chatwootConfig = undefined;
    const config = useConfig();

    expect(config.hostURL).toBeUndefined();
    expect(config.vapidPublicKey).toBeUndefined();
    expect(config.enabledLanguages).toBeUndefined();
    // -------------- Reason ---------------
    // isEnterprise is now hardcoded to true in useConfig.js
    // ------------ Original -----------------------
    // expect(config.isEnterprise).toBe(false);
    // ---------------------------------------------
    // ---------------------- Modification Begin ----------------------
    expect(config.isEnterprise).toBe(true);
    // ---------------------- Modification End ------------------------
    expect(config.enterprisePlanName).toBeUndefined();
  });
});
