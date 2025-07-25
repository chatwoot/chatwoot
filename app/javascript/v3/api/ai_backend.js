import ApiClient from 'dashboard/api/ApiClient';

class ConfigurationBackendAPI extends ApiClient {
  constructor() {
    super('onboarding_config', { accountScoped: true });
  }

  createConfiguration(configKey, configData) {
    const configurationPayload = {
      configuration: {
        key: configKey,
        data: configData,
      },
    };

    return this.create(configurationPayload);
  }
}

export default new ConfigurationBackendAPI();
