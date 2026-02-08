import { getI18nKey } from '../settingsHelper';

describe('settingsHelper', () => {
  describe('getI18nKey', () => {
    it('should return the correct i18n key', () => {
      const prefix = 'CUSTOM_ROLE.PERMISSIONS';
      const event = 'conversation_manage';
      const expectedKey = 'CUSTOM_ROLE.PERMISSIONS.CONVERSATION_MANAGE';

      expect(getI18nKey(prefix, event)).toBe(expectedKey);
    });

    it('should handle different prefixes', () => {
      const prefix = 'INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.EVENTS';
      const event = 'message_created';
      const expectedKey =
        'INTEGRATION_SETTINGS.WEBHOOK.FORM.SUBSCRIPTIONS.EVENTS.MESSAGE_CREATED';

      expect(getI18nKey(prefix, event)).toBe(expectedKey);
    });

    it('should convert event to uppercase', () => {
      const prefix = 'TEST_PREFIX';
      const event = 'lowercaseEvent';
      const expectedKey = 'TEST_PREFIX.LOWERCASEEVENT';

      expect(getI18nKey(prefix, event)).toBe(expectedKey);
    });
  });
});
