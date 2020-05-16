import {
  frontendURL,
  conversationUrl,
  accountIdFromPathname,
} from '../URLHelper';

describe('#URL Helpers', () => {
  describe('conversationUrl', () => {
    it('should return direct conversation URL if activeInbox is nil', () => {
      expect(conversationUrl(1, undefined, 1)).toBe(
        'accounts/1/conversations/1'
      );
    });
    it('should return ibox conversation URL if activeInbox is not nil', () => {
      expect(conversationUrl(1, 2, 1)).toBe(
        'accounts/1/inbox/2/conversations/1'
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

  /* 
  
  export const accountIdFromPathname = pathname => {
  const isInsideAccountScopedURLs = pathname.includes('/app/accounts');
  const accountId = isInsideAccountScopedURLs ? pathname.split('/')[3] : '';
  return Number(accountId);
};

  */

  describe('accountIdFromPathname', () => {
    it('should return account id if accont scoped url is passed', () => {
      expect(accountIdFromPathname('/app/accounts/1/settings/general')).toBe(1);
    });
    it('should return empty string if accont scoped url not is passed', () => {
      expect(accountIdFromPathname('/app/accounts/settings/general')).toBe('');
    });
    it('should return empty string if empty string is passed', () => {
      expect(accountIdFromPathname('')).toBe('');
    });
  });
});
