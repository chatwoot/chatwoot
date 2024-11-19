import { buildPortalArticleURL, buildPortalURL } from '../portalHelper';

describe('PortalHelper', () => {
  describe('buildPortalURL', () => {
    it('returns the correct url', () => {
      window.chatwootConfig = {
        hostURL: 'https://app.chatwoot.com',
        helpCenterURL: 'https://help.chatwoot.com',
      };
      expect(buildPortalURL('handbook')).toEqual(
        'https://help.chatwoot.com/hc/handbook'
      );
      window.chatwootConfig = {};
    });
  });

  describe('buildPortalArticleURL', () => {
    it('returns the correct url', () => {
      window.chatwootConfig = {
        hostURL: 'https://app.chatwoot.com',
        helpCenterURL: 'https://help.chatwoot.com',
      };
      expect(
        buildPortalArticleURL('handbook', 'culture', 'fr', 'article-slug')
      ).toEqual('https://help.chatwoot.com/hc/handbook/articles/article-slug');
      window.chatwootConfig = {};
    });
  });
});
