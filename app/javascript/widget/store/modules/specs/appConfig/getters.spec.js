import { getters } from '../../appConfig';

describe('#getters', () => {
  describe('#getWidgetColor', () => {
    it('returns correct value', () => {
      const state = { widgetColor: '#00bcd4' };
      expect(getters.getWidgetColor(state)).toEqual('#00bcd4');
    });
  });
  describe('#getReferrerHost', () => {
    it('returns correct value', () => {
      const state = { referrerHost: 'www.chatwoot.com' };
      expect(getters.getReferrerHost(state)).toEqual('www.chatwoot.com');
    });
  });
  describe('#getShowUnreadMessagesDialog', () => {
    it('returns correct value', () => {
      const state = { showUnreadMessagesDialog: true };
      expect(getters.getShowUnreadMessagesDialog(state)).toEqual(true);
    });
  });
  describe('#getAvailableMessage', () => {
    it('returns correct value', () => {
      const state = { availableMessage: 'We reply quickly' };
      expect(getters.getAvailableMessage(state)).toEqual('We reply quickly');
    });
  });
  describe('#getWelcomeHeading', () => {
    it('returns correct value', () => {
      const state = { welcomeHeading: 'Hello!' };
      expect(getters.getWelcomeHeading(state)).toEqual('Hello!');
    });
  });
  describe('#getWelcomeTagline', () => {
    it('returns correct value', () => {
      const state = { welcomeTagline: 'Welcome to our site' };
      expect(getters.getWelcomeTagline(state)).toEqual('Welcome to our site');
    });
  });
  describe('#getShowFilePicker', () => {
    it('returns correct value', () => {
      const state = { showFilePicker: true };
      expect(getters.getShowFilePicker(state)).toEqual(true);
    });
  });
  describe('#getShowEmojiPicker', () => {
    it('returns correct value', () => {
      const state = { showEmojiPicker: true };
      expect(getters.getShowEmojiPicker(state)).toEqual(true);
    });
  });
  describe('#getAllowEndConversation', () => {
    it('returns correct value', () => {
      const state = { allowEndConversation: true };
      expect(getters.getAllowEndConversation(state)).toEqual(true);
    });
  });
  describe('#getUnavailableMessage', () => {
    it('returns correct value', () => {
      const state = { unavailableMessage: 'We are offline' };
      expect(getters.getUnavailableMessage(state)).toEqual('We are offline');
    });
  });
  describe('#getIsUpdatingRoute', () => {
    it('returns correct value', () => {
      const state = { isUpdatingRoute: true };
      expect(getters.getIsUpdatingRoute(state)).toEqual(true);
    });
  });
});
