import ApiClient from 'dashboard/api/ApiClient';

class AIBackendAPI extends ApiClient {
  constructor() {
    super('onboarding_config', { accountScoped: true });
  }

  updateOrCreateConfiguration(configKey, configData) {
    const configurationPayload = {
      configuration: {
        key: configKey,
        data: configData,
      },
    };

    return this.create(configurationPayload);
  }
}

export default new AIBackendAPI();
