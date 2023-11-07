import {
  frontendURL,
  conversationUrl,
  isValidURL,
  conversationListPageURL,
  getArticleSearchURL,
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

  describe('getArticleSearchURL', () => {
    it('should generate a basic URL without optional parameters', () => {
      const url = getArticleSearchURL({
        portalSlug: 'news',
        pageNumber: 1,
        locale: 'en',
        host: 'myurl.com',
      });
      expect(url).toBe('myurl.com/news/articles?page=1&locale=en');
    });

    it('should include status parameter if provided', () => {
      const url = getArticleSearchURL({
        portalSlug: 'news',
        pageNumber: 1,
        locale: 'en',
        status: 'published',
        host: 'myurl.com',
      });
      expect(url).toBe(
        'myurl.com/news/articles?page=1&locale=en&status=published'
      );
    });

    it('should include author_id parameter if provided', () => {
      const url = getArticleSearchURL({
        portalSlug: 'news',
        pageNumber: 1,
        locale: 'en',
        authorId: 123,
        host: 'myurl.com',
      });
      expect(url).toBe(
        'myurl.com/news/articles?page=1&locale=en&author_id=123'
      );
    });

    it('should include category_slug parameter if provided', () => {
      const url = getArticleSearchURL({
        portalSlug: 'news',
        pageNumber: 1,
        locale: 'en',
        categorySlug: 'technology',
        host: 'myurl.com',
      });
      expect(url).toBe(
        'myurl.com/news/articles?page=1&locale=en&category_slug=technology'
      );
    });

    it('should include sort parameter if provided', () => {
      const url = getArticleSearchURL({
        portalSlug: 'news',
        pageNumber: 1,
        locale: 'en',
        sort: 'views',
        host: 'myurl.com',
      });
      expect(url).toBe('myurl.com/news/articles?page=1&locale=en&sort=views');
    });

    it('should handle multiple optional parameters', () => {
      const url = getArticleSearchURL({
        portalSlug: 'news',
        pageNumber: 1,
        locale: 'en',
        status: 'draft',
        authorId: 456,
        categorySlug: 'science',
        sort: 'views',
        host: 'myurl.com',
      });
      expect(url).toBe(
        'myurl.com/news/articles?page=1&locale=en&status=draft&author_id=456&category_slug=science&sort=views'
      );
    });

    it('should handle missing optional parameters gracefully', () => {
      const url = getArticleSearchURL({
        portalSlug: 'news',
        pageNumber: 1,
        locale: 'en',
        host: 'myurl.com',
      });
      expect(url).toBe('myurl.com/news/articles?page=1&locale=en');
    });
  });
});
