import {
  buildLocaleMenuItems,
  buildPortalArticleURL,
  buildPortalURL,
} from '../portalHelper';

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

    it('returns the correct url with custom domain', () => {
      window.chatwootConfig = {
        hostURL: 'https://app.chatwoot.com',
        helpCenterURL: 'https://help.chatwoot.com',
      };
      expect(
        buildPortalArticleURL(
          'handbook',
          'culture',
          'fr',
          'article-slug',
          'custom-domain.dev'
        )
      ).toEqual('https://custom-domain.dev/hc/handbook/articles/article-slug');
    });

    it('handles https in custom domain correctly', () => {
      window.chatwootConfig = {
        hostURL: 'https://app.chatwoot.com',
        helpCenterURL: 'https://help.chatwoot.com',
      };
      expect(
        buildPortalArticleURL(
          'handbook',
          'culture',
          'fr',
          'article-slug',
          'https://custom-domain.dev'
        )
      ).toEqual('https://custom-domain.dev/hc/handbook/articles/article-slug');
    });

    it('uses hostURL when helpCenterURL is not available', () => {
      window.chatwootConfig = {
        hostURL: 'https://app.chatwoot.com',
        helpCenterURL: '',
      };
      expect(
        buildPortalArticleURL('handbook', 'culture', 'fr', 'article-slug')
      ).toEqual('https://app.chatwoot.com/hc/handbook/articles/article-slug');
    });
  });

  describe('buildLocaleMenuItems', () => {
    it('disables other actions but keeps customize enabled for the default locale', () => {
      const items = buildLocaleMenuItems({ isDefault: true, isDraft: false });
      const customize = items.find(item => item.action === 'customize-content');

      expect(customize).toBeTruthy();
      expect(customize.disabled).toBeFalsy();
      expect(
        items
          .filter(item => item.action !== 'customize-content')
          .every(item => item.disabled)
      ).toBe(true);
    });

    it('returns publish, customize, and delete actions for draft locales', () => {
      expect(
        buildLocaleMenuItems({
          isDefault: false,
          isDraft: true,
        }).map(({ action }) => action)
      ).toEqual(['publish-locale', 'customize-content', 'delete']);
    });

    it('returns default, draft, customize, and delete actions for live locales', () => {
      expect(
        buildLocaleMenuItems({
          isDefault: false,
          isDraft: false,
        }).map(({ action }) => action)
      ).toEqual([
        'change-default',
        'move-to-draft',
        'customize-content',
        'delete',
      ]);
    });
  });
});
