import { useGlobalConfig } from '../useGlobalConfig';

describe('useGlobalConfig', () => {
  it('should return the string with the installation name', () => {
    const str = 'Chatwoot is awesome';
    const installationName = 'Acme Inc';
    const { useInstallationName } = useGlobalConfig();
    expect(useInstallationName(str, installationName)).toBe(
      'Acme Inc is awesome'
    );
  });

  it('should return the string without the installation name', () => {
    const str = 'Chatwoot is awesome';
    const installationName = '';
    const { useInstallationName } = useGlobalConfig();
    expect(useInstallationName(str, installationName)).toBe(
      'Chatwoot is awesome'
    );
  });

  it('should handle null installation name properly', () => {
    const str = 'Chatwoot is super cool';
    const installationName = null;
    const { useInstallationName } = useGlobalConfig();
    expect(useInstallationName(str, installationName)).toBe(
      'Chatwoot is super cool'
    );
  });

  it('should handle undefined installation name properly', () => {
    const str = 'Chatwoot is super cool';
    const installationName = undefined;
    const { useInstallationName } = useGlobalConfig();
    expect(useInstallationName(str, installationName)).toBe(
      'Chatwoot is super cool'
    );
  });
});
