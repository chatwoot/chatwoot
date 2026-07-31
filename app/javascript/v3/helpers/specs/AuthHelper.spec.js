import {
  getShopifyBillingRedirect,
  getLoginRedirectURL,
  getCredentialsFromEmail,
  getSignupRoute,
  getTargetAccount,
  requiresShopifyBilling,
} from '../AuthHelper';

describe('#URL Helpers', () => {
  describe('getShopifyBillingRedirect', () => {
    it('preserves Shopify App Pricing return parameters', () => {
      expect(
        getShopifyBillingRedirect({
          plan_handle: 'growth',
          shop: 'store.myshopify.com',
        })
      ).toBe('settings/billing?plan_handle=growth&shop=store.myshopify.com');
      expect(getShopifyBillingRedirect({ shop: 'store.myshopify.com' })).toBe(
        'settings/billing?shop=store.myshopify.com'
      );
    });

    it('ignores unrelated login parameters', () => {
      expect(getShopifyBillingRedirect({ email: 'user@example.com' })).toBe('');
    });
  });

  describe('getSignupRoute', () => {
    it('carries a pending Shopify install token into signup', () => {
      expect(
        getSignupRoute(
          'settings/integrations/shopify?shopify_pending_install=0123456789abcdef0123456789abcdef'
        )
      ).toEqual({
        name: 'auth_signup',
        query: {
          shopify_pending_install: '0123456789abcdef0123456789abcdef',
        },
      });
    });

    it('uses the regular signup route for other login redirects', () => {
      expect(getSignupRoute('accounts/1/dashboard')).toEqual({
        name: 'auth_signup',
      });
    });
  });

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

    it('sends a pending feature-enabled Shopify account to billing', () => {
      const user = {
        account_id: 7500,
        accounts: [
          {
            id: 7500,
            billing_provider: 'shopify',
            shopify_integration: true,
            subscription_status: 'pending',
            shopify_shop_domain: 'store.myshopify.com',
          },
        ],
      };

      expect(getLoginRedirectURL({ user })).toBe(
        '/app/accounts/7500/settings/billing'
      );
    });

    it('preserves a Shopify pricing redirect for a pending account after login', () => {
      const user = {
        account_id: 7500,
        accounts: [
          {
            id: 7500,
            billing_provider: 'shopify',
            shopify_integration: true,
            subscription_status: 'pending',
            shopify_shop_domain: 'store.myshopify.com',
          },
        ],
      };

      expect(
        getLoginRedirectURL({
          redirectUrl:
            'settings/billing?plan_handle=growth&shop=store.myshopify.com',
          user,
        })
      ).toBe(
        '/app/accounts/7500/settings/billing?plan_handle=growth&shop=store.myshopify.com'
      );
    });

    it('routes a Shopify pricing return to the account connected to that shop', () => {
      const user = {
        account_id: 7500,
        accounts: [
          {
            id: 7500,
            shopify_shop_domain: 'first-store.myshopify.com',
          },
          {
            id: 7501,
            shopify_shop_domain: 'second-store.myshopify.com',
          },
        ],
      };

      expect(
        getLoginRedirectURL({
          redirectUrl:
            'settings/billing?plan_handle=growth&shop=second-store.myshopify.com',
          user,
        })
      ).toBe(
        '/app/accounts/7501/settings/billing?plan_handle=growth&shop=second-store.myshopify.com'
      );
    });

    it('does not route a Shopify pricing return to an unrelated account', () => {
      const user = {
        account_id: 7500,
        accounts: [
          {
            id: 7500,
            shopify_shop_domain: 'first-store.myshopify.com',
          },
        ],
      };

      expect(
        getLoginRedirectURL({
          redirectUrl:
            'settings/billing?plan_handle=growth&shop=unknown-store.myshopify.com',
          user,
        })
      ).toBe('/app/');
    });

    it('preserves the regular redirect when the Shopify feature is disabled', () => {
      const user = {
        account_id: 7500,
        accounts: [
          {
            id: 7500,
            billing_provider: 'shopify',
            shopify_integration: false,
            subscription_status: 'pending',
          },
        ],
      };

      expect(getLoginRedirectURL({ user })).toBe(
        '/app/accounts/7500/dashboard'
      );
    });
  });

  describe('requiresShopifyBilling', () => {
    it.each(['active', 'trialing', 'cancelled'])(
      'allows the entitled %s state into the product',
      subscriptionStatus => {
        expect(
          requiresShopifyBilling({
            billing_provider: 'shopify',
            shopify_integration: true,
            subscription_status: subscriptionStatus,
          })
        ).toBe(false);
      }
    );

    it.each(['pending', 'missing', 'expired'])(
      'requires billing for the %s state',
      subscriptionStatus => {
        expect(
          requiresShopifyBilling({
            billing_provider: 'shopify',
            shopify_integration: true,
            subscription_status: subscriptionStatus,
          })
        ).toBe(true);
      }
    );
  });

  describe('getTargetAccount', () => {
    it('matches Shopify shop domains case-insensitively', () => {
      const shopifyAccount = {
        id: 7501,
        shopify_shop_domain: 'store.myshopify.com',
      };

      expect(
        getTargetAccount({
          redirectUrl: 'settings/billing?shop=Store.MyShopify.Com',
          user: { accounts: [{ id: 7500 }, shopifyAccount] },
        })
      ).toBe(shopifyAccount);
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
