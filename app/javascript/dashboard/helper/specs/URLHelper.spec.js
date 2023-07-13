import {
  frontendURL,
  conversationUrl,
  isValidURL,
  conversationListPageURL,
} from '../URLHelper';

describe('#URL Helpers', () => {
  describe('conversationListPageURL', () => {
    it('should return url to dashboard', () => {
      expect(conversationListPageURL({ accountId: 1 })).toBe(
        '/app/accounts/1/dashboard'
      );
    });
    it('should return url to inbox', () => {
      expect(conversationListPageURL({ accountId: 1, inboxId: 1 })).toBe(
        '/app/accounts/1/inbox/1'
      );
    });
    it('should return url to label', () => {
      expect(conversationListPageURL({ accountId: 1, label: 'support' })).toBe(
        '/app/accounts/1/label/support'
      );
    });

    it('should return url to team', () => {
      expect(conversationListPageURL({ accountId: 1, teamId: 1 })).toBe(
        '/app/accounts/1/team/1'
      );
    });

    it('should return url to custom view', () => {
      expect(conversationListPageURL({ accountId: 1, customViewId: 1 })).toBe(
        '/app/accounts/1/custom_view/1'
      );
    });
  });
  describe('conversationUrl', () => {
    it('should return direct conversation URL if activeInbox is nil', () => {
      expect(conversationUrl({ accountId: 1, id: 1 })).toBe(
        'accounts/1/conversations/1'
      );
    });
    it('should return inbox conversation URL if activeInbox is not nil', () => {
      expect(conversationUrl({ accountId: 1, id: 1, activeInbox: 2 })).toBe(
        'accounts/1/inbox/2/conversations/1'
      );
    });
    it('should return correct conversation URL if label is active', () => {
      expect(
        conversationUrl({ accountId: 1, label: 'customer-support', id: 1 })
      ).toBe('accounts/1/label/customer-support/conversations/1');
    });
    it('should return correct conversation URL if team Id is available', () => {
      expect(conversationUrl({ accountId: 1, teamId: 1, id: 1 })).toBe(
        'accounts/1/team/1/conversations/1'
      );
    });
  });

  describe('frontendURL', () => {
    it('should return url without params if params passed is nil', () => {
      expect(frontendURL('main', null)).toBe('/app/main');
    });
    it('should return url without params if params passed is not nil', () => {
      expect(frontendURL('main', { ping: 'pong' })).toBe('/app/main?ping=pong');
    });
  });

  describe('isValidURL', () => {
    it('should return true if valid url is passed', () => {
      expect(isValidURL('https://chatwoot.com')).toBe(true);
    });
    it('should return false if invalid url is passed', () => {
      expect(isValidURL('alert.window')).toBe(false);
    });
  });
});
