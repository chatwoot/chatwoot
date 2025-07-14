import ConfigurationFactory from './entities/configurationEntity';
import axios from 'axios';
import DEFAULT_CONFIGS from './entities/configuration/default_configs';

const CONFIGURATION_KEYS = {
  NOTIFICATIONS: 'notification_config',
  MESSAGES: 'messaging_config',
  GENERAL_STORE: 'general_store_config',
  ECOMMERCE: 'ecommerce_config',
  CALENDLY: 'calendly_config',
  CONVERSATION: 'conversation_config',
};

class ChatscommerceConfigurationApi {
  constructor() {
    this.apiUrl = `${window.chatwootConfig.chatscommerceApiUrl}/api/configurations/`;
  }

  static getHeaders() {
    return {
      'Content-Type': 'application/json',
      Authorization: 'application/json',
    };
  }

  async createDefaultStoreConfigs(store_id) {
    const configs = Object.values(CONFIGURATION_KEYS);
    configs.forEach(async config => {
      const configEntity = new ConfigurationFactory(
        DEFAULT_CONFIGS[config],
        config,
        null,
        store_id
      );
      await axios.put(
        `${this.apiUrl}`,
        { configuration: configEntity.toJSON() },
        { headers: this.constructor.getHeaders() }
      );
    });
  }
}

export default new ChatscommerceConfigurationApi();
