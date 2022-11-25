import { buildPortalArticleURL, buildPortalURL } from '../portalHelper';

describe('PortalHelper', () => {
  describe('buildPortalURL', () => {
    it('returns the correct url', () => {
      window.chatwootConfig = {
        hostURL: 'https://app.quicksales.vn',
        helpCenterURL: 'https://help.quicksales.vn',
      };
      expect(buildPortalURL('handbook')).toEqual(
        'https://help.quicksales.vn/hc/handbook'
      );
      window.chatwootConfig = {};
    });
  });

  describe('buildPortalArticleURL', () => {
    it('returns the correct url', () => {
      window.chatwootConfig = {
        hostURL: 'https://app.quicksales.vn',
        helpCenterURL: 'https://help.quicksales.vn',
      };
      expect(buildPortalArticleURL('handbook', 'culture', 'fr', 1)).toEqual(
        'https://help.quicksales.vn/hc/handbook/fr/culture/1'
      );
      window.chatwootConfig = {};
    });
  });
});
