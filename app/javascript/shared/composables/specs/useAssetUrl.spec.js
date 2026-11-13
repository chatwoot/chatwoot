import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { useAssetUrl } from '../useAssetUrl';

describe('useAssetUrl', () => {
  const originalConfig = window.globalConfig;

  afterEach(() => {
    window.globalConfig = originalConfig;
  });

  describe('when globalConfig is missing', () => {
    beforeEach(() => {
      delete window.globalConfig;
    });

    it('returns the path unchanged', () => {
      const assetUrl = useAssetUrl();
      expect(assetUrl('/assets/foo.png')).toBe('/assets/foo.png');
    });
  });

  describe('when ASSET_CDN_HOST is unset', () => {
    beforeEach(() => {
      window.globalConfig = { ASSET_CDN_HOST: '' };
    });

    it('returns the path unchanged', () => {
      const assetUrl = useAssetUrl();
      expect(assetUrl('/audio/dashboard/ding.mp3')).toBe(
        '/audio/dashboard/ding.mp3'
      );
    });
  });

  describe('when ASSET_CDN_HOST is configured', () => {
    beforeEach(() => {
      window.globalConfig = { ASSET_CDN_HOST: 'https://cdn.example.com' };
    });

    it('prefixes the path with the CDN host', () => {
      const assetUrl = useAssetUrl();
      expect(assetUrl('/assets/foo.png')).toBe(
        'https://cdn.example.com/assets/foo.png'
      );
    });

    it('reads the UPPERCASE key', () => {
      window.globalConfig = {
        ASSET_CDN_HOST: 'https://cdn.example.com',
        assetCdnHost: 'https://wrong.example.com',
      };
      const assetUrl = useAssetUrl();
      expect(assetUrl('/foo.png')).toBe('https://cdn.example.com/foo.png');
    });

    it('leaves absolute URLs unchanged', () => {
      const assetUrl = useAssetUrl();
      expect(assetUrl('https://other.example.com/foo.png')).toBe(
        'https://other.example.com/foo.png'
      );
      expect(assetUrl('//cdn.example.org/foo.png')).toBe(
        '//cdn.example.org/foo.png'
      );
    });

    it('returns blank/empty paths unchanged', () => {
      const assetUrl = useAssetUrl();
      expect(assetUrl('')).toBe('');
      expect(assetUrl(null)).toBe(null);
      expect(assetUrl(undefined)).toBe(undefined);
    });
  });

  describe('when ASSET_CDN_HOST has trailing slashes', () => {
    beforeEach(() => {
      window.globalConfig = { ASSET_CDN_HOST: 'https://cdn.example.com///' };
    });

    it('dedupes the trailing slashes', () => {
      const assetUrl = useAssetUrl();
      expect(assetUrl('/foo.png')).toBe('https://cdn.example.com/foo.png');
    });
  });
});
