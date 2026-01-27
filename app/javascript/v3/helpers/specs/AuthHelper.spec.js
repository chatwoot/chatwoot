import { getLoginRedirectURL, getCredentialsFromEmail } from '../AuthHelper';

describe('#URL Helpers', () => {
  describe('getLoginRedirectURL', () => {
    it('should return correct Account URL if account id is present', () => {
      expect(
        getLoginRedirectURL({
          ssoAccountId: '7500',
          user: {
            accounts: [{ id: 7500, name: 'Test Account 7500' }],
          },
        })
      ).toBe('/app/accounts/7500/dashboard');
    });

    it('should return correct conversation URL if account id and conversationId is present', () => {
      expect(
        getLoginRedirectURL({
          ssoAccountId: '7500',
          ssoConversationId: '752',
          user: {
            accounts: [{ id: 7500, name: 'Test Account 7500' }],
          },
        })
      ).toBe('/app/accounts/7500/conversations/752');
    });

    it('should return default URL if account id is not present', () => {
      expect(getLoginRedirectURL({ ssoAccountId: '7500', user: {} })).toBe(
        '/app/'
      );
      expect(
        getLoginRedirectURL({
          ssoAccountId: '7500',
          user: {
            accounts: [{ id: '7501', name: 'Test Account 7501' }],
          },
        })
      ).toBe('/app/accounts/7501/dashboard');
      expect(getLoginRedirectURL('7500', null)).toBe('/app/');
    });
  });

  describe('getCredentialsFromEmail', () => {
    it('should capitalize fullName and accountName from a standard email', () => {
      expect(getCredentialsFromEmail('john@company.com')).toEqual({
        fullName: 'John',
        accountName: 'Company',
      });
    });

    it('should handle subdomains by using the first part of the domain', () => {
      expect(getCredentialsFromEmail('jane@mail.example.org')).toEqual({
        fullName: 'Jane',
        accountName: 'Mail',
      });
    });

    it('should split by dots and capitalize each word', () => {
      expect(getCredentialsFromEmail('john.doe@acme.co')).toEqual({
        fullName: 'John Doe',
        accountName: 'Acme',
      });
    });

    it('should omit everything after + in the local part', () => {
      expect(getCredentialsFromEmail('user+tag@startup.io')).toEqual({
        fullName: 'User',
        accountName: 'Startup',
      });
    });

    it('should split by underscores and hyphens', () => {
      expect(getCredentialsFromEmail('first_last@my-company.com')).toEqual({
        fullName: 'First Last',
        accountName: 'My Company',
      });
    });
  });
});
